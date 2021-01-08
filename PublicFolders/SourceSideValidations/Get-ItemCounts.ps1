function Get-ItemCounts {
    <#
    .SYNOPSIS
        Populates the ItemCount property on our PSCustomObjects.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSCustomObject]
        $FolderData
    )

    begin {
        $startTime = Get-Date
        $progressCount = 0
    }

    process {
        $highestItemCountFolder = $FolderData.IpmSubtree | Sort-Object ItemCount -Descending | Select-Object -First 1

        if ($highestItemCountFolder.ItemCount -lt 1) {
            Get-Mailbox -PublicFolder | Sort-Object DisplayName | ForEach-Object {
                $mailbox = $_
                Get-PublicFolderStatistics -Mailbox $mailbox -ResultSize Unlimited | ForEach-Object {

                    if (++$progressCount % 100 -eq 0) {
                        Write-Progress -Activity "Getting public folder statistics" -Status "$progressCount $mailbox"
                    }

                    if ($_.ItemCount -gt 0) {
                        $folder = $FolderData.EntryIdDictionary[$_.EntryId.ToString()]

                        if ($null -ne $folder) {
                            $folder.ItemCount = $_.ItemCount
                        }
                    }
                }
            }
        }
    }

    end {
        if ($progressCount -gt 0) {
            Write-Progress -Activity "Saving item counts"
            $FolderData.IpmSubtree | Export-Csv $PSScriptRoot\IpmSubtree.csv
        }

        Write-Host "Get-ItemCounts duration" ((Get-Date) - $startTime)
    }
}
