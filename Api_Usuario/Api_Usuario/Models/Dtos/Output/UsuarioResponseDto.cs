namespace Api_Sistema_Usuarios.Models.Dtos.Output
{
    public class UsuarioResponseDto
    {
        public int Id { get; set; }
        public string? Nombre { get; set; } // Corresponde al campo 'Nombre' en PKG_USUARIOS_READ_ALL
        public string? Email { get; set; } // Corresponde al campo 'Email' en PKG_USUARIOS_READ_ALL
        public int RolId { get; set; } // Corresponde al campo 'RolId' en PKG_USUARIOS_READ_ALL
        public string? RolNombre { get; set; } // Corresponde al campo 'RolNombre' en PKG_USUARIOS_READ_ALL
    }
}
