function wdic = add_winners_to_weight(winners, wdic)
    for i = 1 : length(winners.PERMNO)
        index = binarySearchIndex(winners.PERMNO(i))

        if index == -1
            wdic = add_new_row(wdic, winners.PERMNO(i), 0)
        end
    end
end
