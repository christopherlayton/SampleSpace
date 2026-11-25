expect_imported("pyreadstat")
expect_called("read_sav")
expect_type("teach", "DataFrame", message="`pyreadstat.read_sav()` returns the data first: `teach, meta = ...`.")
expect_object("method_labels", {1.0: "Lecture", 2.0: "Active learning"},
              message="`meta.variable_value_labels[\"method\"]` holds them.")
expect_true(get_object("teach_lab") is not None and str(get_object("teach_lab")["method"].iloc[0]) == "Lecture",
            label="`teach_lab` has the labels applied",
            message="Read the file again with `apply_value_formats=True` into `teach_lab, meta_lab`.")
expect_object("n_active", 15, message="Compare the labelled column with the label: `(teach_lab[\"method\"] == \"Active learning\").sum()`.")
expect_object("n_no_answer", 2, message="The \"No answer\" code was declared missing, so it arrives as NaN: `teach[\"anxiety\"].isna().sum()`.")
expect_object("mean_anxiety", 3.1785714285714284, message="`teach[\"anxiety\"].mean()` skips the missing answers.")
