# Hafızada Duran Tüm Değişkenleri Siliyoruz.
Get-Variable -Exclude PWD,*Preference | Remove-Variable -EA 0

[string]$ShadowsDate=Get-Date -Format "ddMMyyyy"

# Gün içerinde Sadece 1 Kere Çalışması için Register üzerinde gerekli kontrolleri yapıyoruz.
$RegisterCheckFolder=Test-Path -Path "HKLM:\SYSTEM\ShadowCopy"

# Yukarıda Belirtilen Regedit Yolunun olup olmadığını kontrol ediyoruz.
if ( $RegisterCheckFolder -eq $false )
   {
   # Kontrol sonucu False gelirse yani yukarıda belirtilen Regedit yolunda belirtilen klasör yoksa yeni biz oluşturuyoruz ve bugün tarihini ShadowCopyDate Dize değerine giriyoruz
   [void](New-Item -Path "HKLM:\SYSTEM" -Name "ShadowCopy") 
   [void](New-ItemProperty -Path "HKLM:\SYSTEM\ShadowCopy" -Name "ShadowsCopyDate" -Value "$ShadowsDate")
   $ShadowCheckStatus=0
   }
else
   {
   # Eğer Eğer True gelirse ShadowcopyDate Dize değerini kontrol ediyoruz
   [string]$ShadowsCopyRegisterDate=(Get-ItemProperty -Path "HKLM:\SYSTEM\ShadowCopy" -Name "ShadowsCopyDate" -ErrorAction SilentlyContinue).ShadowsCopyDate
   
   # Eğer değer null gelirse Bugünün tarihi tekrardan ShadowCopyDate Dize değerine giriyoruz
   if ( $ShadowsCopyRegisterDate -eq "" )
      {
      [void](New-ItemProperty -Path "HKLM:\SYSTEM\ShadowCopy" -Name "ShadowsCopyDate" -Value "$ShadowsDate")
      $ShadowCheckStatus=0
      
      }
     else
      {
     # Eğer okuduğumuz değer Null değil ve bir tarih formatı döndürüyorsa bugünün tarihi ile okunan tarigi karşılaştırıyoruz
     if ( $ShadowsCopyRegisterDate -eq $ShadowsDate )
        {

        $ShadowsCounters=0
        # Register değeri bugün alınmış bir yedek olduğunu söylemesine sağmen biz genede bugün alınmış bir shadow copy varmı diye kontrol ediyor 
        # ve bir counter sayıyoruz.
        Get-WMIObject -Class Win32_ShadowCopy | ForEach-Object {

        $ShadowInstallDate=$_.ConvertToDateTime($_.InstallDate)
        $ShadowDay=[int]$ShadowInstallDate.ToString('ddMMyyyy')

        if ( $ShadowDay -eq $ShadowsDate )
           {
           $ShadowsCounters++
           }

        }

        # Eğer Yukardaki control sonucunda Counter bilgisi 0'dan büyükse  Check Status değeri 1 yapiyoruz ki bugün bir daha shadow copy almasını engelliyoruz
        # Eğer değer sıfır gelirsede Check Status değerini 0 olarak ayarliyoruz böylelikle bugün alınmış bir shadow copy olmadığını
        # düşünerek Shadow Copy almasını sağlıyor olacağız.
        if ( $ShadowsCounters -gt 0 ) { $ShadowCheckStatus=1 } else { $ShadowCheckStatus=0 }
        
        }
    else
       {
        # Eğer yukarda Okuduğumuz Register değerindeki dize değeri bugün tarigi ile eşit değilse bugün tarihi ile değiştiriyoruz ve Check Status değerini 0 yapararak bir Shadow copy almasını sağlıyor olacağız.
        Set-ItemProperty -Path "HKLM:\SYSTEM\ShadowCopy" -Name "ShadowsCopyDate" -Value "$ShadowsDate"
        $ShadowCheckStatus=0
       }
      }

   }


# Eğer Gün içerisinde alınmış bir Gölge Kopyası yoksa Bilgisayardaki Fiziki NTFS Formatlı Disklerin Gölge Kopyasını Almaktadır.
# 8 ve üzeri Restore Point Noktalarını Temizleme
   if ( $ShadowCheckStatus -eq 0 )
      {
 Get-WMIObject -Class Win32_Volume  | Select-Object Name,DeviceID,DriveLetter,DriveType,@{Name="Capacity"; Expression={[math]::round($_.Capacity/1GB)}},FileSystem | Where-Object { $_.DriveType -eq 3 -and $_.DriveLetter -ne $null -and $_.FileSystem -eq "NTFS" -and $_.Capacity -lt 65536 } | ForEach-Object {
       
       
      $DiskDriver=$_.Name 
      $VolumeDeviceId=$_.DeviceID

      [void](gwmi -list win32_shadowcopy).Create($DiskDriver,'ClientAccessible')    
      
   
      Get-WmiObject Win32_Shadowcopy | Where-Object { $_.VolumeName -eq $VolumeDeviceId -and $_.NoWriters -eq $true } | Sort-Object InstallDate -Descending | Select-Object  -Skip 7 | ForEach-Object { $_.Delete() }

      }
      }

