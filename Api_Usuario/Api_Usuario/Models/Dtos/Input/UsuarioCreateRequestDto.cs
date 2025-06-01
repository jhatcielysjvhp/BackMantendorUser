
namespace Api_Sistema_Usuarios.Models.Dtos.Input
{
    public class UsuarioCreateRequestDto
    {
        public string Username { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public int RoleId { get; set; }
        }
    }
