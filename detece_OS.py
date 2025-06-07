import os
import platform
import subprocess
os_type = platform.system()
print(f"Système d'exploitation détecté : {os_type}")
def get_windows_version():
    """Identifie la version de Windows (10, 11, ou Serveur)."""
    try:
        # Exécute une commande PowerShell pour récupérer la version de Windows
        command = "(Get-ItemProperty -Path 'HKLM:SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion').ProductName"
        result = subprocess.run(
            ["powershell.exe", "-Command", command],
            capture_output=True,
            text=True,
            check=True
        )
        version = result.stdout.strip()
        print(f"Version de Windows détectée : {version}")

        # Vérifie si c'est Windows 10, 11 ou Serveur
        if "Windows 10" in version:
            print("Système d'exploitation : Windows 10")
        elif "Windows 11" in version:
            print("Système d'exploitation : Windows 11")
        elif "Server" in version:
            print("Système d'exploitation : Windows Server")
        else:
            print("Version de Windows non reconnue.")
        return version

    except subprocess.CalledProcessError as e:
        print(f"Erreur lors de la récupération de la version de Windows : {e.stderr}")
        return None

def execute_hardening_script(os_type, version=None):
    """Exécute le script de durcissement approprié."""
    try:
        if os_type == "Windows":
            if version == "Windows 10":
                script = "hardening_windows_10.py"
            elif version == "Windows Server":
                script = "hardening_windows_server.py"
            else:
                print("Aucun script de durcissement disponible pour cette version de Windows.")
                return
        elif os_type == "Linux":
            script = "hard.sh"
        else:
            print("Système d'exploitation non supporté pour le durcissement.")
            return

        if os.path.exists(script):
            print(f"Exécution du script : {script}")
            subprocess.run(["python", script], check=True)
        else:
            print(f"Erreur : Le script {script} est introuvable dans le répertoire actuel.")
    except subprocess.CalledProcessError as e:
        print(f"Erreur lors de l'exécution de {script} : {e.stderr}")

if __name__ == "__main__":
    if os_type == "Windows":
        get_windows_version()
        version = get_windows_version()
        if version:
            execute_hardening_script(os_type, version)
    elif os_type == "Linux":
        execute_hardening_script(os_type)