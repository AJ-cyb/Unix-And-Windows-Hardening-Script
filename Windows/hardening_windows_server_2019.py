import subprocess

def run_powershell_command(command, description):
    """Exécute une commande PowerShell avec une description."""
    print(f"Exécution : {description}")
    try:
        result = subprocess.run(["powershell.exe", "-Command", command], capture_output=True, text=True, check=True)
        print(f"Succès : {description}\n{result.stdout}")
    except subprocess.CalledProcessError as e:
        print(f"Erreur lors de {description} :\n{e.stderr}")

def main():
    print("Début du durcissement de Windows Server 2019...\n")

    # Désactiver la compression SMBv3
    run_powershell_command(
        r"Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'DisableCompression' -Value 1",
        "Désactivation de la compression SMBv3"
    )

    # Configurer les règles ASR (Attack Surface Reduction)
    run_powershell_command(
        r"Set-MpPreference -AttackSurfaceReductionRules_Actions 'Enabled' -AttackSurfaceReductionRules_Ids 'D4F940AB-401B-4EFC-AADC-AD5F3C50688A'",
        "Activation des règles ASR"
    )

    # Renforcer les paramètres de mot de passe
    run_powershell_command(
        r"secedit /configure /db C:\Windows\Security\Database\hardening.sdb /cfg C:\Windows\Security\Templates\password_policy.inf",
        "Renforcement des paramètres de mot de passe"
    )

    # Activer le pare-feu Windows
    run_powershell_command(
        "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True",
        "Activation du pare-feu Windows"
    )

    # Désactiver les services inutiles
    services_to_disable = ["Fax", "Spooler", "WSearch", "DiagTrack"]
    for service in services_to_disable:
        run_powershell_command(
            f"Set-Service -Name {service} -Status Stopped -StartupType Disabled",
            f"Désactivation du service {service}"
        )

    # Appliquer des paramètres de registre pour renforcer la sécurité
    registry_settings = [
        {
            "path": r"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System",
            "name": "EnableLUA",
            "value": 1,
            "description": "Activer le contrôle de compte utilisateur (UAC)"
        },
        {
            "path": r"HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters",
            "name": "DisableIPSourceRouting",
            "value": 2,
            "description": "Désactiver le routage des sources IP"
        }
    ]
    for setting in registry_settings:
        command = (
            f"Set-ItemProperty -Path '{setting['path']}' -Name '{setting['name']}' -Value {setting['value']}"
        )
        run_powershell_command(command, setting["description"])

    print("\nDurcissement terminé avec succès. Veuillez redémarrer le serveur pour appliquer toutes les modifications.")

if __name__ == "__main__":
    main()
