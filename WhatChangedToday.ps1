#What Files Changed Today
Get-ChildItem "FILE PATH" -recurse | where-object {$_.lastwritetime -gt (get-date).addDays(-1)}