namespace Api_Sistema_Usuarios.Models
{
    public class Usuario
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string? Email { get; set; }
        public int? RoleId { get; set; }
        public bool Active { get; set; }
    }
}