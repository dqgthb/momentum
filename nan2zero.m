function zerovec = non2zero(vec_w_nan)
    zerovec = non2zero
    zerovec(isnan(zerovec))=0
end
