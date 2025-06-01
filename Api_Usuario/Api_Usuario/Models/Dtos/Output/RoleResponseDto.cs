namespace Api_Sistema_Usuarios.Models.Dtos.Output
{
    public class RoleResponseDto
    {
        public int Id { get; set; }
        public string? Nombre { get; set; } // Corresponde al campo 'Nombre' en PKG_ROLES_READ_ALL
        public int usuarios_count { get; set; } // Corresponde al campo 'usuarios_count' en PKG_ROLES_READ_ALL
    }
}
