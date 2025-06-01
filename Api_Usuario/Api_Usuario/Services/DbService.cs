using System.Data;
using MySqlConnector;
using Microsoft.Extensions.Configuration;

namespace Api_Sistema_Usuarios.Services
{
    public class DbService
    {
        private readonly IConfiguration _configuration;
        private readonly string _connectionString;

        public DbService(IConfiguration configuration)
        {
            _configuration = configuration;
            _connectionString = _configuration.GetConnectionString("DefaultConnection") ?? 
                throw new ArgumentNullException("ConnectionString:DefaultConnection no está configurado");
        }

        public IDbConnection CreateConnection()
            => new MySqlConnection(_connectionString);
    }
}