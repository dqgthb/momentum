%%
M = magic(4);
N = 10;
%%
[ b, ix ] = sort( M(:), 'descend' );
%%
[ rr, cc ] = ind2sub( size(M), ix(1:N) );
%%
for ii = 1 : N
   disp( M( rr(ii), cc(ii) ) )
end
c