expect_imported("seaborn")
expect_imported("matplotlib")
expect_called("histplot")
expect_plot(2, message="Draw two figures, each finished with `plt.show()`.")
expect_true((plot_label("x", 1) or "").lower().startswith("hours"), label="The histogram's x axis says Hours per mission",
            message="After `sns.histplot(...)`, add `plt.xlabel(\"Hours per mission\")` before `plt.show()`.")
_f = get_object("first")
expect_true(_f is not None and len(_f) == 564 and {"age", "decade"} <= set(getattr(_f, "columns", []))
            and sorted(_f["decade"].unique()) == [1960, 1970, 1980, 1990, 2000, 2010],
            label="`first` has age and decade (1960 … 2010)",
            message="`first.assign(age=..., decade=first[\"year_of_mission\"] // 10 * 10)`.")
expect_called("boxplot")
expect_true((plot_label("y", 2) or "").lower().startswith("age"), label="The boxplot's y axis says Age at first flight",
            message="After `sns.boxplot(...)`, add `plt.ylabel(\"Age at first flight\")` before the second `plt.show()`.")
