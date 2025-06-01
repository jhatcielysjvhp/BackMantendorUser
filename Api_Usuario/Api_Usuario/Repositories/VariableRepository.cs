using System.Data;
using Api_Sistema_Usuarios.Models.Dtos.Input; 
using Api_Sistema_Usuarios.Models.Dtos.Output;
using Api_Sistema_Usuarios.Services;
using Dapper;
using System.Collections.Generic;

namespace Api_Sistema_Usuarios.Repositories
{
    public class VariableRepository
    {
        private readonly DbService _dbService;

        public VariableRepository(DbService dbService)
        {
            _dbService = dbService;
        }

        public async Task<(int idGenerado, int resultado, string mensaje)> Create(VariableCreateRequestDto variableDto) 
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_nombre", variableDto.Name);  
            parameters.Add("p_valor", variableDto.Value);  
            parameters.Add("p_tipo", variableDto.Tipo);    
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            parameters.Add("p_id_generado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            
            await connection.ExecuteAsync("PKG_VARIABLES_CREATE", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                parameters.Get<int>("p_id_generado"),
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(VariableResponseDto? variable, int resultado, string mensaje)> GetById(int id)
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_id", id);
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            
            var result = await connection.QueryFirstOrDefaultAsync<VariableResponseDto>("PKG_VARIABLES_READ_BY_ID", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                result,
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(VariableResponseDto? variable, int resultado, string mensaje)> GetByName(string nombre)
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_nombre", nombre);
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            
            var result = await connection.QueryFirstOrDefaultAsync<VariableResponseDto>("PKG_VARIABLES_READ_BY_NAME", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                result,
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(IEnumerable<VariableResponseDto> variables, int resultado, string mensaje)> GetAll(int offset, int limit)
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_offset", offset);
            parameters.Add("p_limit", limit);
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);

            var result = await connection.QueryAsync<VariableResponseDto>("PKG_VARIABLES_READ_ALL", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                result,
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }

        public async Task<(int resultado, string mensaje)> Update(VariableUpdateRequestDto variableDto) 
        {
            using var connection = _dbService.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("p_id", variableDto.Id);        
            parameters.Add("p_nombre", variableDto.Name);  
            parameters.Add("p_valor", variableDto.Value);  
            parameters.Add("p_tipo", variableDto.Tipo);    
            parameters.Add("p_resultado", dbType: DbType.Int32, direction: ParameterDirection.Output);
            parameters.Add("p_mensaje", dbType: DbType.String, direction: ParameterDirection.Output, size: 500);
            
            await connection.ExecuteAsync("PKG_VARIABLES_UPDATE", parameters, commandType: CommandType.StoredProcedure);
            
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
            
            await connection.ExecuteAsync("PKG_VARIABLES_DELETE", parameters, commandType: CommandType.StoredProcedure);
            
            return (
                parameters.Get<int>("p_resultado"),
                parameters.Get<string>("p_mensaje")
            );
        }
    }
}