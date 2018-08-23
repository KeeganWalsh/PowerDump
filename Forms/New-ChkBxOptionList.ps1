#Input a list of options and this will build a form with options and output the selected targets to a file of your choosing
FUNCTION New-ChkBxOptionList($In,$Out){
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "Update Options"
    $objForm.AutoSize = $True
    $objForm.AutoSizeMode = "GrowAndShrink"
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {$OKButton_Click}})
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
        {$objForm.Close()}})
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
    $OnLoadForm_StateCorrection=
    {#Correct the initial state of the form to prevent the .Net maximized form issue
        $objForm.WindowState = $InitialFormWindowState
    }


    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,20) 
    $objLabel.Size = New-Object System.Drawing.Size(280,20) 
    $objLabel.Text = "Take Your Pic:"
    $objForm.Controls.Add($objLabel)     

    $Y = 50
    $X = 25
    $Counter = 0
    $CheckBoxList = FOREACH($I IN $In){
         New-Variable "CheckBox$I" -Value $(new-object System.Windows.Forms.CheckBox -Property @{
            Name = $I
            Text = $I
            Location = New-Object System.Drawing.Size($X,$Y)
            Size = New-Object System.Drawing.Size(200,23)
        })
        $objForm.Controls.Add($(Get-Variable "CheckBox$I" -ValueOnly)) 
        Get-Variable "CheckBox$I" -ValueOnly
        $Y+=50
        $Counter++
        $Z = $Y
        IF($Counter -eq 10){
            $X+=200
            $Y = 50
            $Counter = 0
            $LoopCount++
        }
        IF($LoopCount -gt 1){
        $Z = 550
        }
    }

    $OKButton_Click = {IF(!(Test-Path $Out)){New-Item $Out -ItemType File | Out-Null}ELSE{Clear-Content $Out}
                   FOREACH($Checkbox IN $CheckBoxList){
                    IF($Checkbox.Checked){
                        Add-Content $Out $Checkbox.Name
                    }
                   }
                   ;$objForm.Close()}
                    
    $ALLButton_Click = {IF(!(Test-Path $Out)){New-Item $Out -ItemType File | Out-Null}ELSE{Clear-Content $Out}
                   FOREACH($Checkbox IN $CheckBoxList){
                        Add-Content $Out $Checkbox.Name
                   }
                   ;$objForm.Close()}

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(75,$Z)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $OKButton.Add_Click($OKButton_Click)
    $objForm.Controls.Add($OKButton)

    $ALLButton = New-Object System.Windows.Forms.Button
    $ALLButton.Location = New-Object System.Drawing.Size(150,$Z)
    $ALLButton.Size = New-Object System.Drawing.Size(75,23)
    $ALLButton.Text = "ALL"
    $ALLButton.Add_Click($ALLButton_Click)
    $objForm.Controls.Add($ALLButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(225,$Z)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({$objForm.Close()})
    $objForm.Controls.Add($CancelButton)

    $objForm.Topmost = $True
    #Save the initial state of the form
    $InitialFormWindowState = $objForm.WindowState
    #Init the OnLoad event to correct the initial state of the form
    $objForm.add_Load($OnLoadForm_StateCorrection)
    #Show the Form
    $objForm.ShowDialog()| Out-Null
}