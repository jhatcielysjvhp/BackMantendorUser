namespace Api_Sistema_Usuarios.Models.Dtos.Input
    {
        public class GetUsuariosRequestDto
        {
            public int Offset { get; set; } = 0;
            public int Limit { get; set; } = 100;
        }
    }
