import subprocess
import os

def run_command(command, description):
    """Exécute une commande et affiche un message."""
    try:
        print(f"Exécution : {description}...")
        subprocess.run(command, shell=True, check=True)
        print(f"[OK] {description}")
    except subprocess.CalledProcessError as e:
        print(f"[ERREUR] {description} : {e}")

def check_admin_rights():
    """Vérifie si le script est exécuté avec des droits administratifs."""
    try:
        subprocess.run("net session", check=True, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("[OK] Droits administratifs vérifiés.")
    except subprocess.CalledProcessError:
        print("[ERREUR] Ce script doit être exécuté en tant qu'administrateur.")
        exit(1)

def enable_firewall():
    """Active le pare-feu Windows."""
    run_command("netsh advfirewall set allprofiles state on", "Activation du pare-feu Windows")

def disable_rdp():
    """Désactive le Bureau à Distance (RDP)."""
    run_command('reg add "HKLM\\System\\CurrentControlSet\\Control\\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f', 
                "Desactivation du Bureau à Distance (RDP)")

def reduce_telemetry():
    """Reduit la telemetrie Windows."""
    run_command('reg add "HKLM\\Software\\Policies\\Microsoft\\Windows\\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f', 
                "Reduction de la telemetrie Windows")

def enable_auto_updates():
    """Active les mises à jour automatiques."""
    run_command('reg add "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\WindowsUpdate\\AU" /v NoAutoUpdate /t REG_DWORD /d 0 /f', 
                "Activation des mises à jour automatiques")

def enable_applocker():
    """Active AppLocker."""
    run_command('reg add "HKLM\\Software\\Policies\\Microsoft\\Windows\\SrpV2" /v EnableAppLocker /t REG_DWORD /d 1 /f', 
                "Activation d'AppLocker")

def configure_exploit_guard():
    """Configure Windows Defender Exploit Guard."""
    run_command('reg add "HKLM\\Software\\Microsoft\\Windows Defender\\Windows Defender Exploit Guard" /v ExploitProtectionEnabled /t REG_DWORD /d 1 /f', 
                "Configuration de Windows Defender Exploit Guard")

def enable_application_guard():
    """Active Microsoft Defender Application Guard."""
    run_command('DISM /Online /Enable-Feature /FeatureName:Windows-Defender-ApplicationGuard /NoRestart', 
                "Activation de Microsoft Defender Application Guard")

def limit_shadow_copies():
    """Limite l'espace utilise par les Shadow Copies."""
    run_command("vssadmin resize shadowstorage /on=c: /for=c: /maxsize=5000MB", 
                "Limitation de l'espace alloue aux Shadow Copies")
def check_windows_edition():
    """Vérifie l'édition de Windows."""
    try:
        # Exécute la commande PowerShell pour obtenir l'édition de Windows
        command = "Get-ComputerInfo | Select-Object -ExpandProperty WindowsEditionId"
        result = subprocess.run(
            ["powershell.exe", "-Command", command],
            capture_output=True,
            text=True,
            check=True
        )
        
        windows_edition = result.stdout.strip()
        print(f"Édition de Windows : {windows_edition}")
        return windows_edition
    except subprocess.CalledProcessError as e:
        print(f"Erreur lors de la vérification de l'édition de Windows : {e.stderr}")
        return None

def main():
    """Menu principal du script de durcissement."""
    check_admin_rights()

    print("\n=== Script de durcissement Windows 10 ===")
    options = {
        "1": ("Activer le pare-feu Windows", enable_firewall),
        "2": ("Désactiver le Bureau à Distance (RDP)", disable_rdp),
        "3": ("Réduire la télémétrie Windows", reduce_telemetry),
        "4": ("Activer les mises à jour automatiques", enable_auto_updates),
        "5": ("Activer AppLocker", enable_applocker),
        "6": ("Configurer Exploit Guard", configure_exploit_guard),
        "7": ("Activer Application Guard", enable_application_guard),
        "8": ("Limiter les Shadow Copies", limit_shadow_copies),
        "9": ("Appliquer toutes les mesures", lambda: [
            enable_firewall(),
            disable_rdp(),
            reduce_telemetry(),
            enable_auto_updates(),
            enable_applocker(),
            configure_exploit_guard(),
            enable_application_guard(),
            limit_shadow_copies()
        ]),
        "0": ("Quitter", exit)
    }

    while True:
        print("\n=== Menu ===")
        for key, (desc, _) in options.items():
            print(f"{key}. {desc}")

        choice = input("Choisissez une option : ")
        if choice in options:
            _, action = options[choice]
            action()
        else:
            print("Option invalide. Veuillez réessayer.")

if __name__ == "__main__":
    edition = check_windows_edition()
    if edition:
        if edition in ["Professional", "Enterprise", "Education"]:
            print("Votre édition de Windows est compatible avec certaines fonctionnalités avancées vous pouver continuer.")
        else:
            print("Votre édition de Windows peut ne pas être compatible avec toutes les fonctionnalités avancées tel que option 6:Exploit Guard et 7:Application Guard.")
    main()