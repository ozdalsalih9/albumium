# Run only for a first Play release. Never overwrite an existing upload key.
$ErrorActionPreference = 'Stop'
$signingAndroid = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../android'))
$signingKeyPath = Join-Path $signingAndroid 'upload-keystore.jks'
$signingPropertiesPath = Join-Path $signingAndroid 'key.properties'
if ((Test-Path -LiteralPath $signingKeyPath) -or (Test-Path -LiteralPath $signingPropertiesPath)) {
    throw 'Signing files already exist. Reuse and back them up; do not replace them.'
}
$signingRandom = New-Object byte[] 32
$signingRng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$signingRng.GetBytes($signingRandom)
$signingRng.Dispose()
$signingPassword = [Convert]::ToBase64String($signingRandom)
$env:ALBUMIUM_UPLOAD_PASSWORD = $signingPassword
try {
    & 'C:/Program Files/Java/jdk-17/bin/keytool.exe' -genkeypair -v -keystore $signingKeyPath -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload -dname 'CN=Albumium Upload, OU=Mobile, O=Albumium' -storepass:env ALBUMIUM_UPLOAD_PASSWORD -keypass:env ALBUMIUM_UPLOAD_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw 'Key generation failed' }
    $signingContents = "storePassword=$signingPassword`nkeyPassword=$signingPassword`nkeyAlias=upload`nstoreFile=upload-keystore.jks`n"
    [System.IO.File]::WriteAllText($signingPropertiesPath, $signingContents, [System.Text.UTF8Encoding]::new($false))
    Write-Output 'Upload key and local signing configuration created. Back up both android/upload-keystore.jks and android/key.properties securely.'
} finally {
    Remove-Item Env:ALBUMIUM_UPLOAD_PASSWORD -ErrorAction SilentlyContinue
}
