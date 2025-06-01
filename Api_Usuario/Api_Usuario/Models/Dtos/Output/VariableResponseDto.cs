namespace Api_Sistema_Usuarios.Models.Dtos.Output
{
    public class VariableResponseDto
    {
        public int Id { get; set; }
        public string? Nombre { get; set; } // Corresponde al campo 'Nombre' en PKG_VARIABLES_READ_ALL
        public string? Valor { get; set; } // Corresponde al campo 'Valor' en PKG_VARIABLES_READ_ALL  
        public string? Tipo { get; set; } // Corresponde al campo 'Tipo' en PKG_VARIABLES_READ_ALL
    }
}
