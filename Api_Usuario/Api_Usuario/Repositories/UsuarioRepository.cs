using System.Data;
using Api_Sistema_Usuarios.Models.Dtos.Input; // Actualizado
using Api_Sistema_Usuarios.Models.Dtos.Output; // Actualizado
using Api_Sistema_Usuarios.Services;
using Dapper;
using System.Collections.Generic;

namespace Api_Sistema_Usuarios.Repositories
{
    public class UsuarioRepository
    {
        private readonly DbService _dbService;

        public UsuarioRepository(DbService dbService)
        {
            _dbService = dbService;
        }

        public async Task<(int idGenerado, int resultado, string mensaje)> Create(UsuarioCreateRequestDto usuarioDto) // Modificado para usar DTO de entrada
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_nombre", usuarioDto.Username); 
            parameters.Add("p_email", usuarioDto.Email);     
            parameters.Add("p_rol_id", usuarioDto.RoleId); 
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            parameters.Add("p_id_generado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            
            await connection.ExecuteAsync("PKG_USUARIOS_CREATE", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                parameters.Get<int>("p_id_generado"),
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(UsuarioResponseDto? usuario, int resultado, string mensaje)> GetById(int id)
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_id", id);
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            
            // Dapper mapeará las columnas del SP (Id, Nombre, Email, RolId, RolNombre)
            // a las propiedades del UsuarioResponseDto.
            var result = await connection.QueryFirstOrDefaultAsync<UsuarioResponseDto>("PKG_USUARIOS_READ_BY_ID", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                result,
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(IEnumerable<UsuarioResponseDto> usuarios, int resultado, string mensaje)> GetAll(int offset, int limit)
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_offset", offset);
            parameters.Add("p_limit", limit);
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            
            // El SP ahora devuelve directamente un conjunto de resultados, no a través de cursores
            var result = await connection.QueryAsync<UsuarioResponseDto>("PKG_USUARIOS_READ_ALL", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                result,
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(int resultado, string mensaje)> Update(UsuarioUpdateRequestDto usuarioDto) // Modificado para usar DTO de entrada
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_id", usuarioDto.Id);           
            parameters.Add("p_nombre", usuarioDto.Username); 
            parameters.Add("p_email", usuarioDto.Email); 
            parameters.Add("p_rol_id", usuarioDto.RoleId);   
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            
            await connection.ExecuteAsync("PKG_USUARIOS_UPDATE", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(int resultado, string mensaje)> Delete(int id)
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_id", id);
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            
            await connection.ExecuteAsync("PKG_USUARIOS_DELETE", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }
    }
}