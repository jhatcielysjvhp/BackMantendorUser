namespace Api_Sistema_Usuarios.Models
{
    public class Variable
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Value { get; set; } = string.Empty;
        public string? Tipo { get; set; }
        public string? Description { get; set; }
        public bool Active { get; set; }
    }
}