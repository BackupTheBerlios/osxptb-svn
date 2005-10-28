function rect=AlignRect(rect,fixedRect,side1,side2);
% rect=AlignRect(rect,fixedRect,side1,[side2])
%
% Moves rect to align its top/bottom/left/right with the corresponding
% edge(s) of fixedRect. The legal values for side1 and side2
% are RectLeft, RectRight, RectTop, and RectBottom.
% Also see "help PsychRects".

% Denis Pelli 5/27/96, 7/10/96, 8/5/96

if nargin<3
	error('Usage:  rect=AlignRect(rect,fixedRect,side1,[side2])');
end
if size(rect,2)~=4 | size(fixedRect,2)~=4
	error('Wrong size rect arguments. Usage:  rect=AlignRect(rect,fixedRect,side1,[side2])');
end
if side1<1 | side1>4
	error('Illegal index value.');
end
if side1==RectLeft | side1==RectRight
	rect=OffsetRect(rect,fixedRect(side1)-rect(side1),0);
else
	rect=OffsetRect(rect,0,fixedRect(side1)-rect(side1));
end
if nargin>3
	if side2<1 | side2>4
		error('Illegal index value.');
	end
	if side2==RectLeft | side2==RectRight
		rect=OffsetRect(rect,fixedRect(side2)-rect(side2),0);
	else
		rect=OffsetRect(rect,0,fixedRect(side2)-rect(side2));
	end
end
