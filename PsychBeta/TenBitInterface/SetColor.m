function SetColor(windowPtr,entry,rgb,bitsObsolete)% SetColor(windowPtr,entry,rgb)% % Set the specified "entry" of the clut to the passed "rgb" color spec, e.g. [255; 255; 255] for white.% "entry" must be in the range 0:255.% % Load the hardware CLUT. Works with 8-or-more-bit-DAC graphics cards.% The Radius Thunder, ATI Radeon, and perhaps NVIDIO, have 10-bit DACs.% The BITS++ adapter from Cambridge Research Systems has 14-bit DACs.% http://www.crsltd.com/catalog/bits++/% % The obsolete "bits" argument is ignored.  User programs should be% modified not to pass it.  Eventually this argument will be removed.% % This routine is not intended for time-critical loops.  Use SetClut instead.% % See also SetClut, OpenWindow, CloseWindow, Adjust10BitClut.% 10/29/93  dhb  Wrote it.% 5/23/96   dhb  Add optional windowPtr variable.% 3/29/97   dgp  Updated.% 4/12/97   dhb  Bits arg added.% 2/19/98   dgp  Removed comment that implied that windowPtrOrScreenNumber is optional.% 8/20/00   dhb  Checks for bits, RADIUS.  Implement appropriate special cases.% 10/3/01   bds  Added support for RADEON by changing RADIUS to GAMMA10.% 1/25/02   dhb  Incorporate bds changes into master version.% 2/01/02   dhb  Remove bits_SetColor, add GAMMA10.clut .% 2/07/02   dhb  Update to match SetClut.  Not really tested.% 2/28/02   dhb, ly, kr  Deal with high 10-bit cards.% 3/20/02		dgp  Cosmetic.% 4/19/02   dgp  Changed "color" to "entry" which seems clearer and conforms to usage elsewhere, eg Screen SetClut.% 5/02/02   dhb,kr  Fixed bug introduced by dgp on 4/19.  Not all instances of color were changed.% 7/9/02    dhb  Just use LoadClut.% 8/x/02    dhb  Some intermediate versions using GetClut. % 8/9/02    dhb  Back to enhanced LoadClut, remove passed bitsObsolete argument.LoadClut(windowPtr,rgb',entry);