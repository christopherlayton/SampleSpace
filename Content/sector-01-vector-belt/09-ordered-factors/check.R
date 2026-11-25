labs <- c("Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree")
expect_class("agree_f", "factor")
f <- get_object("agree_f")
expect_true(is.ordered(f), label = "`agree_f` is ordered",
            message = "Add `ordered = TRUE` so the categories have an order.")
expect_true(identical(levels(f), labs), label = "Levels run from Strongly disagree to Strongly agree",
            message = "Use `levels = 1:5, labels = likert_labels` so every code gets its words, in order.")
expect_true(identical(as.character(f), labs[c(4, 2, 5, 3, 4, 1, 5, 4)]),
            label = "Each answer has the right label",
            message = "Make `agree_f` from `agree`, with `levels = 1:5`.")
expect_object("n_agree", 5,
              message = "Five people answered Agree or Strongly agree. Try `sum(agree_f >= \"Agree\")`.")
