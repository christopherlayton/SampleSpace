expect_object("class_mean", 60)
expect_object("class_sd", 5)
expect_object("z", 1.6, message = paste(
  "`z` should be 1.6. If you got 67, R divided before subtracting:",
  "put the subtraction in parentheses, `(my_score - class_mean) / class_sd`."))
z_lines <- grep("^\\s*z\\s*(<-|=)", strsplit(learner_code(), "\n")[[1]], value = TRUE)
expect_true(any(grepl("class_mean", z_lines) & grepl("class_sd", z_lines)),
            label = "`z` is calculated from the objects",
            message = "Use the object names in the formula: `(my_score - class_mean) / class_sd`.")
expect_object("z_classmate", -1.6, message = paste(
  "`z_classmate` should be -1.6: the classmate is 1.6 SDs *below* the mean."))
expect_called("round")
expect_printed(1.6, label = "Prints `z` rounded to 2 decimals",
               message = "Put `round(z, digits = 2)` on a line by itself so it prints.")
