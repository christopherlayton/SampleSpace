truth <- utils::read.csv("crew_morale.csv")
items <- paste0("m", 1:6)
l <- get_object("morale_long")
expect_true(is.data.frame(l) && nrow(l) == nrow(truth) * 6 && all(c("item", "rating") %in% names(l)),
            label = "`morale_long` has one row per person per item (288 rows)",
            message = "Use `pivot_longer(m1:m6, names_to = \"item\", values_to = \"rating\")`.")
s <- get_object("item_summary")
want <- vapply(items, function(i) mean(truth[[i]], na.rm = TRUE), 1)
miss <- vapply(items, function(i) sum(is.na(truth[[i]])), 1)
ok <- is.data.frame(s) && nrow(s) == 6 && all(c("item", "mean_rating", "n_missing") %in% names(s))
expect_true(ok, label = "`item_summary` has one row per item with `mean_rating` and `n_missing`",
            message = "`group_by(item)`, then `summarise(mean_rating = ..., n_missing = ...)`.")
if (ok) {
  s <- as.data.frame(s)[order(s$item), ]
  expect_true(isTRUE(all.equal(as.numeric(s$mean_rating), as.numeric(want))),
              label = "`mean_rating` ignores missing answers",
              message = "Some items have missing answers: `mean(rating, na.rm = TRUE)`.")
  expect_true(identical(as.numeric(s$n_missing), as.numeric(miss)),
              label = "`n_missing` counts the missing answers per item",
              message = "Count NAs with `sum(is.na(rating))`.")
}
expect_object("lowest_item", items[which.min(want)])
w <- get_object("morale_wide")
expect_true(is.data.frame(w) && nrow(w) == nrow(truth) && all(items %in% names(w)) &&
              isTRUE(all.equal(as.numeric(w$m3), as.numeric(truth$m3))),
            label = "`morale_wide` is back to one row per person",
            message = "Use `pivot_wider(names_from = item, values_from = rating)` on `morale_long`.")
expect_called("pivot_longer")
expect_called("pivot_wider")
