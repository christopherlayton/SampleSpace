expect_printed(40, label = "Prints the total sample size",
               message = "I don't see N = 40 in the output yet. Add 23 and 17 on a line by itself.")
expect_printed(7, label = "Prints the mean score",
               message = paste("I don't see the mean (7) yet. If you got 14.33, R divided 10 by 3",
                               "before adding. Put the sum in parentheses first, then divide by 3."))
expect_no_error()
