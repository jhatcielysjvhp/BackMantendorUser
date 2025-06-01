using System.Data;
using Api_Sistema_Usuarios.Models.Dtos.Input; // Actualizado
using Api_Sistema_Usuarios.Models.Dtos.Output; // Actualizado
using Api_Sistema_Usuarios.Services;
using Dapper;
using System.Collections.Generic;

namespace Api_Sistema_Usuarios.Repositories
{
    public class RoleRepository
    {
        private readonly DbService _dbService;

        public RoleRepository(DbService dbService)
        {
            _dbService = dbService;
        }

        public async Task<(int idGenerado, int resultado, string mensaje)> Create(RoleCreateRequestDto roleDto) // Modificado para usar DTO de entrada
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_nombre", roleDto.Name); 
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            parameters.Add("p_id_generado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            
            await connection.ExecuteAsync("PKG_ROLES_CREATE", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                parameters.Get<int>("p_id_generado"),
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(RoleResponseDto? role, int resultado, string mensaje)> GetById(int id)
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_id", id);
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            
            // Dapper mapeará las columnas del SP (Id, Nombre, usuarios_count)
            // a las propiedades del RoleResponseDto.
            var result = await connection.QueryFirstOrDefaultAsync<RoleResponseDto>("PKG_ROLES_READ_BY_ID", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                result,
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(IEnumerable<RoleResponseDto> roles, int totalRegistros, int resultado, string mensaje)> GetAll(int offset, int limit)
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_offset", offset);
            parameters.Add("p_limit", limit);
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            parameters.Add("p_total_registros", dbType: DbType.Int32, direction: ParameterDirection.Output);

            // El SP ahora devuelve directamente un conjunto de resultados, no a través de cursores
            var result = await connection.QueryAsync<RoleResponseDto>("PKG_ROLES_READ_ALL", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                result,
                parameters.Get<int>("p_total_registros"),
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(int resultado, string mensaje)> Update(RoleUpdateRequestDto roleDto) // Modificado para usar DTO de entrada
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_id", roleDto.Id); 
            parameters.Add("p_nombre", roleDto.Name);  
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            
            await connection.ExecuteAsync("PKG_ROLES_UPDATE", parameters, commandType: CommandType.StoredProcedure);
            
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
            
            await connection.ExecuteAsync("PKG_ROLES_DELETE", parameters, commandType: CommandType.StoredProcedure);
                
            return (
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }
    }
}