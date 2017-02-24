function [out_char,ok] = string_chars_num(input,length)
%STRING_CHARS_NUM Generates a character array with a fixed determined
%length from a number. If the input is longer, output is a char array of
%'0's of the specified length and if it is shorter, it is filled with '0'
%at left.
%   INPUT:
%   input: Input number
%   length: Desired length of the output character array
%
%   OUTPUT:
%   out_char: Output character array
%   ok: 0 if input longer that length, 1 otherwise
%
% - L. Ramírez (April 2013)
% - F. Mendoza (February 2017) Update

number = num2str(input);

if numel(number) <= length
    filling(1:(length-numel(number))) = '0';
    out_char = [filling number];
    ok = 1;
else
    out_char(1:length)='0';
    ok = 0;
end
end
