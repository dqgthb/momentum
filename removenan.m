function vec_wo_nan = removenan(vec_w_nan)
    vec_wo_nan = vec_w_nan;
    vec_wo_nan(isnan(vec_wo_nan))=[];
end
