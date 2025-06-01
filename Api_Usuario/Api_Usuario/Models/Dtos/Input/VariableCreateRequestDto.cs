
    namespace Api_Sistema_Usuarios.Models.Dtos.Input
    {
        public class VariableCreateRequestDto
        {
            public string Name { get; set; } = string.Empty;
            public string Value { get; set; } = string.Empty;
            public string Tipo { get; set; } = string.Empty; // 'texto', 'numerico', 'booleano'
        }
    }
