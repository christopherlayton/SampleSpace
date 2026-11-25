expect_object("age", 34)
expect_class("age", "numeric")
expect_object("participant_id", "P017")
expect_class("participant_id", "character",
             message = "Put the ID in quotes so it's text: `\"P017\"`.")
expect_object("consented", TRUE)
expect_class("consented", "logical",
             message = "Write `TRUE` with no quotes; `\"TRUE\"` would be text.")
expect_object("mixed_class", "character",
              message = "`mixed_class` should be the answer from `class(mixed)`.")
expect_called("class")
