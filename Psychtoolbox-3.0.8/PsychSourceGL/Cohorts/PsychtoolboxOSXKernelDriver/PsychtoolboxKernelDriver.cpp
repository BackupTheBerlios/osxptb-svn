/*
	File:			PsychtoolboxKernelDriver.cpp
	
	Description:	This file implements a I/O Kit driver kernel extension (KEXT) for Psychtoolbox-3.
					The driver allows to augment the standard graphics driver with some useful features
					for visual psychophysics applications. It is orthogonal to the systems driver in that
					it doesn't change that drivers functionality, nor does it interact with that driver.
					
					The driver currently only works on AMD/ATI Radeon graphics cards of the X1000, HD2000
					and HD3000 series. It may work on older ATI cards, but that is not tested or supported.
					
					The driver is experimental in nature, with some small but non-zero chance of causing
					malfunctions or crashes of your system, so USE AT YOUR OWN RISK AND WITH CAUTION!
					
					The following features are currently supported:
					
					* Time-Stamped Rasterbeamposition queries on Intel-based Macintosh computers.
					* A function to quickly synchronize the video refresh cycles of the two output heads of
					  a dual-head graphics card, e.g., for binocular or stereo stimulation on dual-display setups.
					* Guided queries and logging of a few intersting gfx-state registers for vision science applications.
					* A low level interface for reading- and writing from/to arbitrary gfx-hardware control registers.
					* A dump function that dumps interesting settings to the system log.
					
					The rasterbeamposition queries and fast dual-head syncing are used by Psychtoolbox if
					the driver is loaded at Screen() startup time.
					
					All other features can be accessed by the stand-alone UNIX command line tool
					"PsychtoolboxKernelDriverUserClientTool", to be found in the PsychAlpha subfolder.

	Copyright:		Copyright © 2008 Mario Kleiner, derived from an Apple example code.

	Change History of original Apple sample code (most recent first):

            1.1			05/22/2007			User client performs endian swapping when called from a user process 
											running using Rosetta. Updated to produce a universal binary.
											Now requires Xcode 2.2.1 or later to build.
			
			1.0d3	 	01/14/2003			New sample.

*/


#include <IOKit/IOLib.h>
#include <IOKit/assert.h>
#include "PsychUserKernelShared.h"
#include "PsychtoolboxKernelDriver.h"


#define super IOService
OSDefineMetaClassAndStructors(PsychtoolboxKernelDriver, IOService)

/* The start() method is called at driver load time: It tries to find the MMIO register
 * range of the ATI Radeon X1000/HD2000/HD3000/HDxxx series graphics cards and then
 * memory-maps it into our own virtual address space, so we can read/write registers
 * by simple memory access. It will also query a few registers and print out their
 * values to the system-log.
 *
 */
bool PsychtoolboxKernelDriver::start(IOService* provider)
{
    bool					success;
	UInt8					pciBARReg;
	IOMemoryDescriptor *	mem;
    IOMemoryMap *			map;
    IOPhysicalAddress		candidate_phys_addr;
    IOPhysicalLength		candidate_size;
    UInt32					candidate_count = 0;
	const char*				providerName = NULL;
	
	// Say Hello ;-)
    IOLog("%s::start() called from IOKit. Starting up and trying to attach to GPU:\n", (getName()) ? getName() : "PTB-3");
	
	// Start our parent provider:
    success = super::start(provider);
	if (!success) return (false);

	// Our provider is start'ed...

    /*
     * Our provider class is specified in the driver property table
     * as IOPCIDevice, so the provider must be of that class.
     * The assert is just to make absolutely sure for debugging.
     */
    assert( OSDynamicCast( IOPCIDevice, provider ));

	// It is a PCI device, check if it's a display driver:
	// Our info.plist for this kext is set up, so it only matches for
	// PCI devices which are graphics cards, and whose vendor is AMD/ATI,
	// so we should be reasonably safe up to that point. Of course it could
	// be something else than the supported X1000, HD2000, HD3000, HDxxx series
	// cards...

	// Double check if we're connected to proper provider:
	// Actually, don't: Keeping track of all the different incompatible names that
	// Apple gives to the provider is too much of a hazzle for small benefit :(
	providerName = provider->getName();
	IOLog("%s: Our provider service is: %s\n", getName(), providerName);
	/*
	if (!provider->compareName(OSString::withCStringNoCopy("display")) && !(providerName && providerName[0]=='G' && providerName[1]=='F' && providerName[2]=='X')) {
		// Not connected to "display" provider :-( Better abort...
		IOLog("%s: Not connected to expected provider with name 'display' or 'GFX0'. Unsafe to continue, i'll better abort...\n", getName());
		return(false);
	}
	*/
	
	// ioreg -b -x -p IODeviceTree -n display 

	// Ok, store internal reference to our provider:
    fPCIDevice = (IOPCIDevice *) provider;

	// Read PCI configuration register 0, a 16 bit register with the
	// Vendor ID. Match it against NVidia's id:
	if (PCI_VENDOR_ID_NVIDIA == fPCIDevice->configRead16(0)) {
		// Assume it is a NVIDIA GeForce GPU: BAR 0 is the MMIO registers:
		pciBARReg = kIOPCIConfigBaseAddress0;
		fDeviceType = kPsychGeForce;
		IOLog("%s: This is a NVidia GPU, hopefully a compatible GeForce...\n", getName());
	}
	else {
		// Assume it is a ATI Radeon GPU: BAR 2 is the MMIO registers:
		pciBARReg = kIOPCIConfigBaseAddress2;
		fDeviceType = kPsychRadeon;
		IOLog("%s: This is a ATI/AMD GPU, hopefully a compatible Radeon...\n", getName());
		if (PCI_VENDOR_ID_ATI == fPCIDevice->configRead16(0)) IOLog("%s: Confirmed to have ATI's vendor id.\n", getName());
		if (PCI_VENDOR_ID_AMD == fPCIDevice->configRead16(0)) IOLog("%s: Confirmed to have AMD's vendor id.\n", getName());
	}

    /*
     * Enable memory response from the card
     */
    fPCIDevice->setMemoryEnable( true );

    /*
     * Log some info about the device
     */	

/*	// DEBUG CODE: Detect both parents and clients of our provider... Left here for documentation, not useful in current impl.
	OSIterator * clientiter = provider->getClientIterator();
	OSObject* client;
	
	for (client = clientiter->getNextObject(); client; client = clientiter->getNextObject()) {
		altProvider = (IOService*) client;
		IOLog("Client is %s\n", altProvider->getName());
		if (altProvider->compareName(OSString::withCStringNoCopy("ATY,Wormy"))) break;
	}
	clientiter->release();
	if (altProvider->compareName(OSString::withCStringNoCopy("ATY,Wormy"))) {
		IOLog("Radeon driver found!\n");
	}
	else {
		altProvider = NULL;
	}
	
//	altProvider = provider->getClient();
//	if (altProvider) altProvider = altProvider->getProvider();
	if (altProvider) {
		IOLog("Our providers provider is %s\n", altProvider->getName());
		
		
		int irq = 0;
		int irqtype;
		IOReturn rc;
		while(irq < 10 && kIOReturnNoInterrupt != (rc=altProvider->getInterruptType(irq, &irqtype))) {
			IOLog("IRQ %ld available: Type %ld Status %lx (%s)\n", irq, irqtype, rc, (irqtype == kIOInterruptTypeLevel) ? "Leveltriggered" : "Other"); irq++;
		}
		
		rc = altProvider->registerInterrupt(0, this, OSMemberFunctionCast(IOInterruptAction, this, &PsychtoolboxKernelDriver::fastPathInterruptHandler));
		IOLog("Resultcode for reg. interrupt 0: %lx (%s)\n", rc, (rc == kIOReturnNoResources) ? "No ressources" : "Other");
		if (rc == kIOReturnSuccess) {
			altProvider->enableInterrupt(0);
			IOSleep(1000);
			altProvider->disableInterrupt(0);
			altProvider->unregisterInterrupt(0);
		}

	}
	
*/

	// Perform complex probing and double-checking on Radeon GPU's:
	if (fDeviceType == kPsychRadeon) {
		/* print all the device's memory ranges */
		for( UInt32 index = 0;
			 index < fPCIDevice->getDeviceMemoryCount();
			 index++ ) {
			
			mem = fPCIDevice->getDeviceMemoryWithIndex( index );
			assert( mem );
			IOLog("%s: PCI Range[%ld] %08lx:%08lx\n", getName(), index, mem->getPhysicalAddress(), mem->getLength());
			
			// Find the MMIO range of expected size around 0x10000: We find the one with size > 0x1000 and not bigger
			// than 0x10000, ie. in the range 4 Kb < size < 64 Kb. This likely represents the register space.
			
			// Much bigger than 0x10000 would be either 3D engine command FIFO's or VRAM framebuffer. Much smaller
			// would be the PCI config space registerset (or maybe VGA set?!?)
			if (mem->getLength() >= 0x1000 && mem->getLength() <= 0x10000) {
				// A possible candidate:
				candidate_phys_addr = mem->getPhysicalAddress();
				candidate_size = mem->getLength();
				candidate_count++;
				IOLog("%s: ==> AMD/ATI Radeon PCI Range[%ld] %08lx:%08lx is %ld. candidate for register block.\n", getName(), index, mem->getPhysicalAddress(), mem->getLength(), candidate_count);
			}
		}
		
		/* More than one candidate found? */
		if (candidate_count != 1) {
			IOLog("%s: Found %i candidates for Radeon register block. Not equal one - Ambigous mapping! Not good...\n", getName(), candidate_count);		
		}
		
		/* look up a range based on its config space base address register */
		mem = fPCIDevice->getDeviceMemoryWithRegister(pciBARReg);
		if( mem ) {
			IOLog("%s: Range@0x%x %08lx:%08lx\n", getName(), pciBARReg, mem->getPhysicalAddress(), mem->getLength());
		}
		else {
			IOLog("%s: Could not find MMIO mapping for config base address register 0x%x!\n", getName(), pciBARReg);
		}
		
		/* Exactly one candidate found and mapping consistent with config register mapping? */
		if (candidate_count != 1 || mem == NULL || candidate_phys_addr != mem->getPhysicalAddress() || candidate_size != mem->getLength()) {
			IOLog("%s: Could not resolve relevant MMIO register block unambigously!! Will abort here - this is not a safe ground for proceeding.\n", getName());
			
			// Detach our device handle, so our cleanup routine won't do anything later on:
			fPCIDevice = NULL;
			
			// We will exit with "success", but the fPCIDevice == NULL signals failure whenever any
			// of our methods gets called, so we are basically idle from now on...
			return(success);
		}

		// End of Radeon specific probing.
	}
	
	// Ok, we think we have a good candidate for the MMIO block in "mem". Let's try to map it
	// into our address space...
	
    /* map a range based on its config space base address register,
     * this is how the driver gets access to its memory mapped registers
     * the getVirtualAddress() method returns a kernel virtual address
     * for the register mapping */
    map = fPCIDevice->mapDeviceMemoryWithRegister( pciBARReg );
    if( map ) {
        IOLog("%s: GPU MMIO register block Range@0x%x (%08lx) mapped to kernel virtual address %08x\n", getName(),
                pciBARReg,
                map->getPhysicalAddress(),
                map->getVirtualAddress());
        /* Assign the map object, and the mapping itself to our private members: */
		fRadeonMap = map;
		fRadeonRegs = map->getVirtualAddress();
		fRadeonSize = (UInt32) map->getLength();
    }
	else {
		// Failed! Cleanup and exit:
		IOLog("%s: Could not memory-map relevant MMIO register block into my kernel memory address space! Will abort here - this is not a safe ground for proceeding.\n", getName());

		// Detach our device handle, so our cleanup routine won't do anything later on:
		fPCIDevice = NULL;
		
		// We will exit with "success", but the fPCIDevice == NULL signals failure whenever any
		// of our methods gets called, so we are basically idle from now on...
		return(success);
	}

	// Execute an I/O memory barrier, so order of execution and CPU <-> GPU sync is guaranteed:
	OSSynchronizeIO();
	
	// The following code chunk if enabled, will detaching the Radeon driver IRQ handler and
	// instead attach our own fastPathInterruptHandler() to IRQ 1 of Radeon GPU's.
	//
	// Detaching the Radeon driver seems to do "limited damage" to OS/X operation:
	//
	// 1. Our VBL userspace timestamping doesn't work anymore, because it relies on VBL timestamps from the driver
	//    This gets detected, handled and reported by PTB's consistency checks -- So this is a good method of
	//    fault-injection for testing PTB's self-diagnostic.
	//
	// 2. The window-server behaves more "nervous", e.g., mouse movements become slightly more jerky,
	//    probably due to the server not getting any timestamps from the driver anymore, so it can't
	//    smooth out display updates in time for a smooth experience. However, OpenGL/PTB seems to operate
	//    normally and the general system/GUI is still very useable -- A noticeable, but not really problematic
	//    nuisance.
	//
	//	  Of course, this behaviour may change on each different gfx-card and OS/X release, so it is
	//    not desirable for production use -- Tradeoffs all over the place...
	if (false && (fDeviceType == kPsychRadeon)) {
		// Setup our own interrupt handler for gfx-card interrupts:
		if (!InitializeInterruptHandler()) {
			// Failed!
			IOLog("%s: Could not install our snoop - interrupt handler! This is non-fatal, will continue...\n", getName());
		}
		else {
			// :-)
			IOLog("%s: Graphics card IRQ Snoop - interrupt handler installed. Cool :-)\n", getName());
		}
	}

	// We should be ready...
	IOLog("\n");
	IOLog("%s: Psychtoolbox-3 kernel-level support driver V1.1 for ATI Radeon and NVidia GeForce GPU's ready for use!\n", getName());
	IOLog("%s: This driver is copyright 2008, 2009, 2010 Mario Kleiner and the Psychtoolbox-3 project developers.\n", getName());
	IOLog("%s: The driver is licensed to you under GNU General Public License (GPL) Version 2 or later,\n", getName());
	IOLog("%s: see the file License.txt in the Psychtoolbox root installation folder for details.\n", getName());
	
	// If everything worked, we publish ourselves and our services:
    if (success) {
		// Publish ourselves so clients can find us
		registerService();
	}
    
	// Return final startup state:
    return success;
}


/* The stop() method is called at driver shutdown time: It checks if we're attached to
 * a gfx-card. If so, we unmap the register control block, detach, and clean up after
 * ourselves.
 */
void PsychtoolboxKernelDriver::stop(IOService* provider)
{
	IOWorkLoop* myWorkLoop = getWorkLoop();
	
    IOLog("%s::stop() request from IOKit: Shutting down...\n", getName());
    
	// Perform cleanup:
	if (fPCIDevice) {

		// Disable, detach and delete our interrupt handler, if any:
		if (fInterruptSrc) {
			fInterruptSrc->disable();
			// TODO: Some kind of release() function or detach from Workloop needed here?
			myWorkLoop->removeEventSource(fInterruptSrc);
			fInterruptSrc->release();
			
			IOLog("%s::stop(): Final total interrupt count is %ld.\n", getName(), fInterruptCounter);
			IOLog("%s::stop(): Final VBL interrupt counts are Head[0] = %ld, Head[1] = %ld \n", getName(), fVBLCounter[0], fVBLCounter[1]);
			fastPathInterruptHandler(NULL, NULL);

			fInterruptSrc = NULL;
			fInterruptCookie = 0xdeadbeef;
			fInterruptCounter = 0;
		}

		// Detach our device handle:
		fPCIDevice = NULL;
		
		// Release memory mapping, if any:
		if (fRadeonMap) {
			IOLog("%s::stop(): Releasing MMIO memory mapped GPU register block...\n", getName());
			fRadeonMap->release();
		}
		
		// NULL-Out our now stale references:
		fRadeonMap = NULL;
		fRadeonRegs = NULL;
		fRadeonSize = 0;		
	}
	
	IOLog("%s::stop(): Driver is stopped and ready for jettisoning or restart...\n", getName());

	// Call our parents stop routine:
    super::stop(provider);
}


/* The init() method is called at the very beginning of the driver life-cycle: Set our member
 * variables to safe and clean defaults:
 */
bool PsychtoolboxKernelDriver::init(OSDictionary* dictionary)
{
    IOLog("PTB::init() called at driver load time...\n");
    
    if (!super::init(dictionary)) {
        return false;
	}

	fDeviceType = kPsychUnknown;
	fPCIDevice = NULL;
	fRadeonMap = NULL;
	fRadeonRegs = NULL;
	fRadeonSize = 0;
	fInterruptSrc = NULL;
	fInterruptCookie = 0xdeadbeef;
	fInterruptCounter = 0;
	fVBLCounter[0] = 0;
	fVBLCounter[1] = 0;

	return true;
}


// We override free only to log that it has been called to make it easier to follow the driver's lifecycle.
void PsychtoolboxKernelDriver::free(void)
{
    IOLog("%s::free() called at module jettisoning time -- Shutdown complete. Bye!\n", getName());
    
    super::free();
}


// We override probe only to log that it has been called to make it easier to follow the driver's lifecycle.
// Production drivers can override probe if they need to make an active decision whether the driver is appropriate for
// the provider.
IOService* PsychtoolboxKernelDriver::probe(IOService* provider, SInt32* score)
{
    IOLog("PTB::probe() request from IOKit received...\n");
        
    IOService *res = super::probe(provider, score);

    return res;
}


// We override willTerminate only to log that it has been called to make it easier to follow the driver's lifecycle.
//
// willTerminate is called at the beginning of the termination process. It is a notification
// that a provider has been terminated, sent before recursing up the stack, in root-to-leaf order.
//
// This is where any pending I/O should be terminated. At this point the user client has been marked
// inactive and any further requests from the user process should be returned with an error.
bool PsychtoolboxKernelDriver::willTerminate(IOService* provider, IOOptionBits options)
{
    if (false) IOLog("%s::willTerminate()\n", getName());
	
	return super::willTerminate(provider, options);
}


// We override didTerminate only to log that it has been called to make it easier to follow the driver's lifecycle.
//
// didTerminate is called at the end of the termination process. It is a notification
// that a provider has been terminated, sent after recursing up the stack, in leaf-to-root order.
bool PsychtoolboxKernelDriver::didTerminate(IOService* provider, IOOptionBits options, bool* defer)
{
    if (false) IOLog("%s::didTerminate()\n", getName());
	
	return super::didTerminate(provider, options, defer);
}


// We override terminate only to log that it has been called to make it easier to follow the driver's lifecycle.
// Production drivers will rarely need to override terminate. Termination processing should be done in
// willTerminate or didTerminate instead.
bool PsychtoolboxKernelDriver::terminate(IOOptionBits options)
{
    bool	success;
    
    if (false) IOLog("%s::terminate()\n", getName());

    success = super::terminate(options);
    
    return success;
}


// We override finalize only to log that it has been called to make it easier to follow the driver's lifecycle.
// Production drivers will rarely need to override finalize.
bool PsychtoolboxKernelDriver::finalize(IOOptionBits options)
{
    bool	success;
    
    if (false) IOLog("%s::finalize()\n", getName());
    
    success = super::finalize(options);
    
    return success;
}

// Initialize our own interrupt handler for snooping on gfx-card state changes
// that are interesting to Psychtoolbox, e.g., buffer swaps. This handler can
// also trigger event-based actions, e.g., emit a hardware trigger signal in
// response to a completed double-buffer swap:
bool PsychtoolboxKernelDriver::InitializeInterruptHandler(void)
{
	// Reset our special debug-members:
	fInterruptCookie = 0xdeadbeef;
	fInterruptCounter = 0;

	// Get handle to our assigned IOKit workloop:
	IOWorkLoop * myWorkLoop = (IOWorkLoop *) getWorkLoop();
    if (!myWorkLoop) {
		// Failed!
		IOLog("%s: In IRQ handler setup: Failed to get my workloop!\n", getName());
		return(false);
	}

	// Dump current IRQ status of GPU:
	IOLog("%s: In IRQ handler setup: Initial: Current hw irqControl is %lx.\n", getName(), ReadRegister(RADEON_R500_GEN_INT_CNTL));
	IOLog("%s: In IRQ handler setup: Initial: Current hw irqStatus is  %lx.\n",	getName(), ReadRegister(RADEON_R500_GEN_INT_STATUS));

	// Disable currently attached ATI interrupt handler on IRQ1 and detach it:
	if (kIOReturnSuccess != fPCIDevice->disableInterrupt(1)) {
		IOLog("%s: In IRQ handler setup: Failed to disable IRQ1 on Display provider!\n", getName());
		return(false);
	}

	// Dump current IRQ status of GPU:
	IOLog("%s: In IRQ handler setup: After disable IRQ: Current hw irqControl is %lx.\n", getName(), ReadRegister(RADEON_R500_GEN_INT_CNTL));
	IOLog("%s: In IRQ handler setup: After disable IRQ: Current hw irqStatus is  %lx.\n",	getName(), ReadRegister(RADEON_R500_GEN_INT_STATUS));

	if (kIOReturnSuccess != fPCIDevice->unregisterInterrupt(1)) {
		fPCIDevice->enableInterrupt(1);
		IOLog("%s: In IRQ handler setup: Failed to detach IRQ1 handler on Display provider! Old handler reenabled...\n", getName());
		return(false);
	}

	IOLog("%s: In IRQ handler setup: ATI IRQ1 handler on Display provider permanently detached...\n", getName());

	// Dump current IRQ status of GPU:
	IOLog("%s: In IRQ handler setup: After detach IRQ: Current hw irqControl is %lx.\n", getName(), ReadRegister(RADEON_R500_GEN_INT_CNTL));
	IOLog("%s: In IRQ handler setup: After detach IRQ: Current hw irqStatus is  %lx.\n",	getName(), ReadRegister(RADEON_R500_GEN_INT_STATUS));

	// Option A: Attach a filter handler in the primary interrupt path, and a deferred workloop handler
	// in the workloop --> More flexible than option B, but both don't yield useable results at the end
	// of the day :-(
	//
    // Create and register an interrupt event source. Our PCI provider will
    // take care of the low-level interrupt registration stuff.
    fInterruptSrc = IOFilterInterruptEventSource::filterInterruptEventSource(this,
                    OSMemberFunctionCast(IOInterruptEventAction, this, &PsychtoolboxKernelDriver::workLoopInterruptHandler),
                    OSMemberFunctionCast(IOFilterInterruptAction, this, &PsychtoolboxKernelDriver::fastPathInterruptHandler),
                    fPCIDevice,
					1);
	if (!fInterruptSrc) {
		// Failed!
		IOLog("%s: In IRQ handler setup: Failed to get and attach an interrupt source for IRQ 1!\n", getName());
		return(false);
	}

	// Attach our interrupt source/handlers to the workloop:
    if (myWorkLoop->addEventSource(fInterruptSrc) != kIOReturnSuccess) {
		// TODO: Some kind of release() function or detach from Workloop needed here?
		fInterruptSrc = NULL;
		IOLog("%s: In IRQ handler setup: Failed to attach our interrupt source to our workloop!\n", getName());
		return(false);
    }


/*  // Option B: Direct attachment to primary interrupt: Works as good as option A, but maybe A is a bit cleaner...
	if (kIOReturnSuccess != fPCIDevice->registerInterrupt(1, this, OSMemberFunctionCast(IOInterruptAction, this, &PsychtoolboxKernelDriver::fastPathInterruptHandler))) {
		IOLog("%s: In IRQ handler setup: Failed to attach our interrupt handler for Radeon IRQ1 on Display provider!\n", getName());
		return(false);
	}
*/

	if (kIOReturnSuccess != fPCIDevice->enableInterrupt(1)) {
		IOLog("%s: In IRQ handler setup: Failed to reenable IRQ1 on Display provider!\n", getName());
		return(false);
	}
	
	// Ok, ready to rock: Enable interrupt handling:
	fInterruptSrc->enable();
	myWorkLoop->enableAllInterrupts();
	
	// Dump current IRQ status of GPU:
	IOLog("%s: In IRQ handler setup: After setup IRQ: Current hw irqControl is %lx.\n", getName(), ReadRegister(RADEON_R500_GEN_INT_CNTL));
	IOLog("%s: In IRQ handler setup: After setup IRQ: Current hw irqStatus is  %lx.\n",	getName(), ReadRegister(RADEON_R500_GEN_INT_STATUS));

	// Acknowledge all pending IRQ's via a special-call to our fastPathInterruptHandler:
	fastPathInterruptHandler(NULL, (IOFilterInterruptEventSource*) 0x1);
	
	// Return success status:
	return(true);
}

// Fast-Path interrupt handler: Gets called in direct primary hardware interrupt context!
// --> CAUTION - Think twice before doing anything here!!!
bool PsychtoolboxKernelDriver::fastPathInterruptHandler(OSObject* myself, IOFilterInterruptEventSource* mySource)
{
	static UInt32 myCounter = 0;
	static UInt32 irqStatus = 0xdeadbeef;
	static UInt32 displayirqStatus = 0;
	
	// Special readout request from outside interrupt path?
	if (myself == NULL && mySource == NULL) {
		// Yes: Log current internal counters value to log:
		IOLog("Internal fastPath invocation count [total number of hardware interrupts on this line] is %ld.\n", myCounter);
		IOLog("Internal fastPath irqStatus is %lx.\n", irqStatus);
		IOLog("Current hw irqControl is %lx.\n",	ReadRegister(RADEON_R500_GEN_INT_CNTL));
		IOLog("Current hw irqStatus is  %lx.\n",	ReadRegister(RADEON_R500_GEN_INT_STATUS));

		return(false);
	}

	// Regular call from interrupt subsystem. Do your thing...

	// Increment internal counter for debug purpose: This one can be read out at
	// shutdown time by a fastPathInterruptHandler(NULL, NULL) call, *after* the
	// handler has been detached from actual interrupt dispatch system!
	myCounter++;
	
	// Check if we have an address space reference to our member variables. If the
	// cookie 0xdeadbeef is found, we can (hopefully) safely access our member
	// variables. If that isn't the case, we're unable to access our members and
	// therefore to do a single useful thing.
	if(fInterruptCookie == 0xdeadbeef) {
		// Ok, member access seems to be safe. Do our actual job:
		
		// Retrieve the current interrupt status of the Radeon card:
		irqStatus = 0;
		irqStatus = ReadRegister(RADEON_R500_GEN_INT_STATUS);
		
		// We are specifically interested in display interrupts: Any such?
		if (irqStatus & RADEON_R500_DISPLAY_INT_STATUS) {
			// Display interrupt! Which one?
			displayirqStatus = ReadRegister(RADEON_R500_DISP_INTERRUPT_STATUS);
			
			// Handle IRQ acknowledge and triggered actions per display pipe:
			if (displayirqStatus & RADEON_R500_D1_VBLANK_INTERRUPT) {
				// Display head 0 [Pipe 1]:
				WriteRegister(RADEON_R500_D1MODE_VBLANK_STATUS, RADEON_R500_VBLANK_ACK);

				// Perform whatever actions need to be performed:
				handleVBLIRQ(0);
			}

			if (displayirqStatus & RADEON_R500_D2_VBLANK_INTERRUPT) {
				// Display head 1 [Pipe 2]:
				WriteRegister(RADEON_R500_D2MODE_VBLANK_STATUS, RADEON_R500_VBLANK_ACK);

				// Perform whatever actions need to be performed:
				handleVBLIRQ(1);
			}
		}
		
		// Acknowledge IRQs, if any:
		if (irqStatus) WriteRegister(RADEON_R500_GEN_INT_STATUS, irqStatus);
		
		// Increment the gloabl fInterruptCounter which counts the graphics cards interrupts we're interested in:
		fInterruptCounter++;
	}
	
	// We return false, so no secondary workloop handler is triggered and hardware
	// interrupts don't get disabled:
	return(false);
}

// Slow-Path WorkLoop interrupt handler: Gets called if the fast-path handler returns "true".
// Will be scheduled/executed by the IOWorkloop with some (possibly significant, non-deterministic)
// latency after the real hardware event has occured. Can use more of IOKit API without disaster.
void PsychtoolboxKernelDriver::workLoopInterruptHandler(OSObject* myself, IOInterruptEventSource* mySource, int pendingIRQs)
{
	// Nothing to do yet: Just return.
	return;
}

// Handle VBLANK IRQ's for display head 'headId':
void PsychtoolboxKernelDriver::handleVBLIRQ(UInt32 headId)
{
	// Increment per-head counter:
	fVBLCounter[headId]++;
	
	return;
}

// Register access convenience functions:

// Read 32 bit control register at 'offset':
UInt32	PsychtoolboxKernelDriver::ReadRegister(UInt32 offset)
{
	// Safety check: Don't allow reads past devices MMIO range:
	// We don't return error codes and don't log the problem,
	// because we could be called from primary Interrupt path, so IOLog() is not
	// an option!
	if (fRadeonRegs == NULL || offset < 0 || offset >= fRadeonSize-4) return(0);
	
	// Read and return value:
	return(OSReadLittleInt32((void*) fRadeonRegs, offset));
}

// Write 32 bit control register at 'offset' with 'value':
void PsychtoolboxKernelDriver::WriteRegister(UInt32 offset, UInt32 value)
{
	// Safety check: Don't allow writes past devices MMIO range:
	// We don't return error codes and don't log the problem,
	// because we could be called from primary Interrupt path, so IOLog() is not
	// an option!
	if (fRadeonRegs == NULL || offset < 0 || offset >= fRadeonSize-4) return;

	// Write the register in correct byte order:
	OSWriteLittleInt32((void*) fRadeonRegs, offset, value);

	// Execute memory I/O barrier to make sure that writes happen in-order and properly synced between CPU and GPU/PCI card:
	OSSynchronizeIO();

	return;
}

// This blob of code will disable the GPU's output dithering for
// flat-panels reliably. It will also cause interference with the
// OS/X graphics stack and GPU hangs pretty reliably on many operations
// thereafter, e.g., cursor movements between dual-display screens, display
// mode changes and redetections, gamma LUT updates etc... It kills all
// functionality which accesses the same command FIFO that our blob uses...
// -> Proof-of-concept, but pretty unuseable in production systems :-(
void PsychtoolboxKernelDriver::G80DispCommand(UInt32 addr, UInt32 data)
{
	UInt32 headId, super, v;

    WriteRegister(0x00610304, data);
    WriteRegister(0x00610300, addr | 0x80010001);

    while(ReadRegister(0x00610300) & 0x80000000) {
        v = (ReadRegister(0x00610024) >> 4) & 7;
		super = 0;
		if (v > 0) {
			while(true) {
				super++;
				if (v & 0x1) break;
				v = v >> 1;
			}
		}

        if(super) {
            if(super == 2) {
				for (headId = 0; headId<2; headId++) {
					const int headOff = 0x800 * headId;
                    if ( (ReadRegister(0x00614200 + headOff) & 0xc0) == 0x80 ) {
						IOLog("%s: IN G80DispCommand: Would need to call G80CrtcSetPClk(%i); but not implemented! Prepare for trouble!!!\n", getName(), headId);
                        // No way to implement this without pulling in lot's of code from XServer's NVidia driver: G80CrtcSetPClk(headId);
					}
                }
            }
			
            WriteRegister(0x00610024, 8 << super);
            WriteRegister(0x00610030, 0x80000000);
        }
    }
}

// Try to change hardware dither mode on GPU:
void PsychtoolboxKernelDriver::SetDitherMode(UInt32 headId, UInt32 ditherOn)
{
	//	printf("GEFORCE DITHER TEST: Head[%i] = %i \n", headId, ditherOn);
	UInt32 headOff = 0x400 * headId;

    G80DispCommand(0x000008A0 + headOff, (ditherOn) ? 0x11 : 0); // G80DispCommand

	// Do we need this?!? Sounds like potential troublemaker:
	// Yes, we do! Change doesn't take effect without.   
	G80DispCommand(0x00000080, 0);

	//	printf("GEFORCE DITHER TEST DONE - ANY CHANGE?\n");

	return;
}

// Return current vertical rasterbeam position of display head 'headId' (0=Primary CRTC1, 1=Secondary CRTC2):
UInt32 PsychtoolboxKernelDriver::GetBeamPosition(UInt32 headId)
{
	SInt32					beampos;

	// Read raw beampostion from GPU:
	beampos = (SInt32) (ReadRegister((headId == 0) ? RADEON_D1CRTC_STATUS_POSITION : RADEON_D2CRTC_STATUS_POSITION) & RADEON_VBEAMPOSITION_BITMASK);

	// Query end-offset of VBLANK interval of this GPU and correct for it:
	beampos = beampos - (SInt32) ((ReadRegister((headId == 0) ? AVIVO_D1CRTC_V_BLANK_START_END : AVIVO_D2CRTC_V_BLANK_START_END) >> 16) & RADEON_VBEAMPOSITION_BITMASK);
	
	// Correction for in-VBLANK range:
	if (beampos < 0) beampos = ((SInt32) ReadRegister((headId == 0) ? AVIVO_D1CRTC_V_TOTAL : AVIVO_D2CRTC_V_TOTAL)) + beampos;

	// Safety measure: Cap to zero if something went wrong -> This will trigger proper high level error handling in PTB:
	if (beampos < 0) beampos = 0;

	if (0) {
		SInt32 vblend, vblstart, vtotal;
		vblend = (SInt32) ((ReadRegister((headId == 0) ? AVIVO_D1CRTC_V_BLANK_START_END : AVIVO_D2CRTC_V_BLANK_START_END) >> 16) & RADEON_VBEAMPOSITION_BITMASK);
		vblstart = (SInt32) ((ReadRegister((headId == 0) ? AVIVO_D1CRTC_V_BLANK_START_END : AVIVO_D2CRTC_V_BLANK_START_END) >> 0) & RADEON_VBEAMPOSITION_BITMASK);
		vtotal = (SInt32) ReadRegister((headId == 0) ? AVIVO_D1CRTC_V_TOTAL : AVIVO_D2CRTC_V_TOTAL);
		IOLog("%s: VBLANK_END %ld VBLANK_START %ld VTOTAL %ld\n", getName(), vblend, vblstart, vtotal);
	}
	
	return((UInt32) beampos);
}

// Instantaneously resynchronize display heads of a Radeon dual-head gfx-card:
SInt32	PsychtoolboxKernelDriver::FastSynchronizeAllDisplayHeads(void)
{
	SInt32					deltabeampos;
	UInt32					beampos0, beampos1;
	UInt32					old_crtc_master_enable = 0;
	UInt32					new_crtc_master_enable = 0;

	IOLog("%s: FastSynchronizeAllDisplayHeads(): About to resynchronize all display heads by use of a 1 second CRTC stop->start cycle:\n", getName());
	
	// A little pretest...
	IOLog("%s: Pretest...\n", getName());
	for (UInt32 i = 0; i<10; i++) { 
		beampos0 = GetBeamPosition(0);
		beampos1 = GetBeamPosition(1);
		IOLog("%s: Sample %ld: Beampositions are %ld vs. %ld . Offset %ld\n", getName(), i, beampos0, beampos1, (SInt32) beampos1 - (SInt32) beampos0);
	}

	// Query the CRTC scan-converter master enable state: Bit 0 (value 0x1) controls Pipeline 1,
	// whereas Bit 1(value 0x2) controls Pipeline 2:
	old_crtc_master_enable = ReadRegister(RADEON_DC_CRTC_MASTER_ENABLE);
	IOLog("%s: Current CRTC Master enable state is %ld . Trying to stop and reset all display heads.\n", getName(), old_crtc_master_enable);
	IOLog("%s: Will wait individually for each head to get close to scanline 0, then disable it.\n", getName());

	// Shut down heads, one after each other, each one at the start of a new refresh cycle:
	for (UInt32 i = 0; i <= 1; i++) { 
		// Wait for head i to start a new display cycle (scanline 0), then shut it down - well if it is active at all:
		IOLog("%s: Head %ld ...  ", getName(), i);
		if (old_crtc_master_enable & (0x1 << i)) {		
			IOLog("active -> Shutdown. ");
			// Wait for beam going above scanline 240: We choose 240, because even at the lowest conceivable
			// useful display resolution of 640 x 480, 240 will be in the middle of the frame, aka far away
			// from both, the start and the end of a frame:
			while (GetBeamPosition(i) <= 240);
			
			// Beam is heading for the end of the frame + VBL area. Wait for wrap-around, ie. until
			// reaching a scanline value smaller than 100 --> Until it wraps back to zero or at least
			// a value close to zero:
			while (GetBeamPosition(i) > 240);
			
			// Start of new refresh interval! Shut down this heads CRTC!
			// We do so by clearing enable bit for this head:
			WriteRegister(RADEON_DC_CRTC_MASTER_ENABLE, ReadRegister(RADEON_DC_CRTC_MASTER_ENABLE) & ~(0x1 << i));
			IOLog("New state is %ld.\n", ReadRegister(RADEON_DC_CRTC_MASTER_ENABLE));

			// Head should be down, close to scanline 0.
			IOSleep(50);
		}
		else {
			IOLog("already offline.\n");
		}
	}

	// Disable all display heads:
	// WriteRegister(RADEON_DC_CRTC_MASTER_ENABLE, 0);
	IOSleep(20);
	
	// Query current beamposition and check state:
	beampos0 = GetBeamPosition(0);
	beampos1 = GetBeamPosition(1);
	
	new_crtc_master_enable = ReadRegister(RADEON_DC_CRTC_MASTER_ENABLE);

	if (new_crtc_master_enable == 0) {
		IOLog("%s: CRTC's down (state %ld): Beampositions are [0]=%ld and [1]=%ld. Synchronized restart in 1 second...\n", getName(), new_crtc_master_enable, beampos0, beampos1);
	}
	else {
		IOLog("%s: CRTC's shutdown failed!! (state %ld): Beamposition are [0]=%ld and [1]=%ld. Will try to restart in 1 second...\n", getName(), new_crtc_master_enable, beampos0, beampos1);
	}
	
	// Sleep for 1 secs == 1000 milliseconds: This is a blocking call, ie. the thread goes to sleep and may wakeup a bit later:
	IOSleep(1000);
	
	// Reset all display heads enable state to original setting:
	WriteRegister(RADEON_DC_CRTC_MASTER_ENABLE, old_crtc_master_enable);

	// Query position and state after restart:
	beampos0 = GetBeamPosition(0);
	beampos1 = GetBeamPosition(1);
	new_crtc_master_enable = ReadRegister(RADEON_DC_CRTC_MASTER_ENABLE);
	if (new_crtc_master_enable == old_crtc_master_enable) {
		IOLog("%s: CRTC's restarted in sync: Master enable state is %ld. Beampositions after restart: [0]=%ld and [1]=%ld.\n", getName(), new_crtc_master_enable, beampos0, beampos1);
	}
	else {
		IOLog("%s: CRTC's restart FAILED!!: Master enable state is %ld. Beampositions: [0]=%ld and [1]=%ld.\n", getName(), new_crtc_master_enable, beampos0, beampos1);
	}

	deltabeampos = (SInt32) beampos1 - (SInt32) beampos0;
	IOLog("%s: Residual beam offset after display sync: %ld.\n\n", getName(), deltabeampos);

	// A little posttest...
	IOLog("%s: Posttest...\n", getName());
	for (UInt32 i = 0; i<10; i++) { 
		beampos0 = GetBeamPosition(0);
		beampos1 = GetBeamPosition(1);
		IOLog("%s: Sample %ld: Beampositions are %ld vs. %ld . Offset %ld\n", getName(), i, beampos0, beampos1, (SInt32) beampos1 - (SInt32) beampos0);
	}
	
	IOLog("\n%s: Display head resync operation finished.\n\n", getName());
	
	// Return offset after (re-)sync:
	return(deltabeampos);
}

// Perform instant state snapshot of interesting registers and return'em:
void PsychtoolboxKernelDriver::GetStateSnapshot(PsychKDCommandStruct* outStruct)
{
	// TODO...
	return;
}

// Dump interesting register state to system log:
void PsychtoolboxKernelDriver::DumpGfxState(void)
{
	UInt32 regidx;
	UInt32 col;
	
	// Output some range of registers to IOLog:
	for (regidx = 0; regidx <= 0x200; regidx+=4) {
		IOLog("Reg[%lx] = %lx :: ", regidx, ReadRegister(regidx));
		if ((col++) % 5 == 0) IOLog("\n");
	}
	
	return;
}

/*
IOReturn PsychtoolboxKernelDriver::ScalarIStructI(int inNumber, MySampleStruct* inStruct, IOByteCount inStructSize)
{
    IOLog("SimpleDriver::ScalarIStructI(inNumber = %d, int16 = %d, int32 = %d, inStructSize = %d)\n",
		  inNumber, inStruct->int16, (int)inStruct->int32, (int)inStructSize);
    
    return kIOReturnSuccess;
}


IOReturn PsychtoolboxKernelDriver::ScalarIStructO(int inNumber1, int inNumber2, MySampleStruct* outStruct, IOByteCount* outStructSize)
{
    IOLog("SimpleDriver::ScalarIStructO(inNumber1 = %d, inNumber2 = %d)\n", inNumber1, inNumber2);
    
    // The scalars inNumber1 and inNumber2 are automatically endian-swapped by the user client mechanism.
	// The user client will swap the fields in outStruct if necessary.
	
	// The output is simply the two input scalars copied to the output struct.
	outStruct->int16 = inNumber1;
    outStruct->int32 = inNumber2;
    *outStructSize = sizeof(MySampleStruct);
    
    return kIOReturnSuccess;
}


IOReturn PsychtoolboxKernelDriver::ScalarIScalarO(int inNumber1, int inNumber2, int* outNumber)
{
    IOLog("SimpleDriver::ScalarIScalarO(inNumber1 = %d, inNumber2 = %d)\n", inNumber1, inNumber2);
    
    // The output is the product of the two input scalars.
	*outNumber = inNumber1 * inNumber2;
    
    return kIOReturnSuccess;
}
*/

IOReturn PsychtoolboxKernelDriver::PsychKDDispatchCommand(PsychKDCommandStruct* inStruct, PsychKDCommandStruct* outStruct, IOByteCount inStructSize, IOByteCount* outStructSize)
{
	// Default return value is success:
    IOReturn ret = kIOReturnSuccess;
	
	// Fetch command code:
	UInt32 cmd = inStruct->command;
	
	// Validate it:
	if (cmd < 0 || cmd >= kPsychKDMaxCommands) {
		IOLog("%s: Invalid/Unknown command code received - Out of range.\n", getName());
		return(kIOReturnBadArgument);
	}
	
	// Dispatch depending on command code:
	switch(cmd) {
		case kPsychKDFastSyncAllHeads:	// Fast synchronize all display heads:
			// One return argument, the residual offset after sync:
			outStruct->inOutArgs[0] = FastSynchronizeAllDisplayHeads();
		break;

		case kPsychKDDumpMiscInfo:		// Dump miscellaneous info about gfx-state to System log:
			// No arguments, just do it:
			DumpGfxState();
		break;
		
		case kPsychKDGetBeamposition:	// Query current beamposition for a specific display head:
			// One input, the headid. One output, the beamposition:
			outStruct->inOutArgs[0] = GetBeamPosition(inStruct->inOutArgs[0]);
		break;

		case kPsychKDGetStateSnapshot:	// Perform snapshot of many relevant registers and return it timestamped:
			GetStateSnapshot(outStruct);
		break;

		case kPsychKDReadRegister:		// Read specific register and return its value:
			outStruct->inOutArgs[0] = ReadRegister(inStruct->inOutArgs[0]);
		break;

		case KPsychKDWriteRegister:		// Write value to specific register:
			WriteRegister(inStruct->inOutArgs[0], inStruct->inOutArgs[1]);
		break;

		case kPsychKDSetDitherMode:		// Write value to specific register:
			SetDitherMode(inStruct->inOutArgs[0], inStruct->inOutArgs[1]);
		break;

		default:
			ret = kIOReturnBadArgument;
			IOLog("%s: Invalid/Unknown command code received - No match in dispatch table.\n", getName());
	}
	
    *outStructSize = sizeof(PsychKDCommandStruct);

    return kIOReturnSuccess;
}
