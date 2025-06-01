# Sistema Usuarios API

Esta es una API de backend construida con ASP.NET Core 8 que gestiona usuarios, roles y variables del sistema.

## Requisitos Previos

*   [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) o superior.
*   Un entorno de desarrollo como Visual Studio 2022, VS Code, o cualquier editor de texto y la l�nea de comandos.
*   Acceso a una base de datos compatible y la cadena de conexi�n correspondiente. La API utiliza un servicio `DbService` para las operaciones de base de datos.

## Configuraci�n

1.  **Clonar el Repositorio :**
    ```bash
    git clone https://github.com/jhatcielysjvhp/BackMantendorUser
    cd <NOMBRE_DEL_DIRECTORIO_DEL_PROYECTO>
    ```

2.  **Configurar la Cadena de Conexi�n:**
    La API requiere una cadena de conexi�n para acceder a la base de datos. Esta configuraci�n se encuentra t�picamente en el archivo `appsettings.json` o, para desarrollo local, en `appsettings.Development.json`. Aseg�rate de que la secci�n `ConnectionStrings` est� configurada correctamente. Ejemplo:

    ```json
    {
      "ConnectionStrings": {
        "DefaultConnection": "Server=localhost;Port=3306;Database=sistema_usuarios;User=dev_user;Password=dev_password"
      },
      // ... otras configuraciones
    }
    ```
 
 las credenciales de la cadena de conexion seran segun la configuracion de Maria BD

    El servicio `DbService` utilizar� esta cadena para establecer la conexi�n.

3.  **Restaurar Dependencias:**
    Abre una terminal en el directorio ra�z del proyecto (donde se encuentra el archivo `.csproj` de la API, por ejemplo, `Api_Usuario.csproj`) y ejecuta:
    ```bash
    dotnet restore
    ```

## Ejecutar la API

Puedes ejecutar la API usando el CLI de .NET o directamente desde Visual Studio.

### Usando el CLI de .NET

1.  Navega al directorio del proyecto en la terminal.
2.  Ejecuta el siguiente comando:
    ```bash
    dotnet run
    ```
    Por defecto, la API se ejecutar� en un puerto asignado (com�nmente `https://localhost:7XXX` y `http://localhost:5XXX`). La consola mostrar� las URLs exactas.

### Usando Visual Studio

1.  Abre el archivo de soluci�n (`.sln`) o el archivo de proyecto (`.csproj`) en Visual Studio.
2.  Selecciona el proyecto `Api_Usuario` como proyecto de inicio.
3.  Presiona `F5` o haz clic en el bot�n de "Iniciar" (normalmente con un icono de reproducci�n verde).

## Acceder a la API

Una vez que la API est� en ejecuci�n:

*   **Endpoints de la API:** Los controladores (`UsuariosController`, `RolesController`, `VariablesController`) definen las rutas base como `/api/Usuarios`, `/api/Roles`, y `/api/Variables`.
*   **Documentaci�n Swagger:** Puedes acceder a la interfaz de Swagger UI para explorar y probar los endpoints de la API. Si la API se est� ejecutando localmente en el entorno de desarrollo, la encontrar�s en:
    *   `https://localhost:PUERTO/swagger` (reemplaza `PUERTO` con el puerto HTTPS correspondiente, ej. 7281)
    *   `http://localhost:PUERTO/swagger` (reemplaza `PUERTO` con el puerto HTTP correspondiente, ej. 5281)

## CORS

La API est� configurada para permitir solicitudes CORS desde `http://localhost:4200` por defecto, como se define en `Program.cs`. Si tu aplicaci�n frontend se ejecuta en un origen diferente, deber�s ajustar la pol�tica CORS.
en este caso es un proyecto Angular en desarrollo local.

## Estructura del Proyecto (Ejemplo)
