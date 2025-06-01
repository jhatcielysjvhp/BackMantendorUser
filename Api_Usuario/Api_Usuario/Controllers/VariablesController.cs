using Microsoft.AspNetCore.Mvc;
using Api_Sistema_Usuarios.Models;
using Api_Sistema_Usuarios.Models.Dtos;
using Api_Sistema_Usuarios.Models.Dtos.Input; // Importar DTOs de entrada
using Api_Sistema_Usuarios.Models.Dtos.Output; // Importar DTOs de salida
using Api_Sistema_Usuarios.Repositories;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace Api_Sistema_Usuarios.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class VariablesController : ControllerBase
    {
        private readonly VariableRepository _variableRepository;

        public VariablesController(VariableRepository variableRepository)
        {
            _variableRepository = variableRepository;
        }

        // POST: api/Variables/list
        [HttpPost("list")]
        public async Task<ActionResult<IEnumerable<VariableResponseDto>>> ListVariables([FromBody] GetVariablesRequestDto request)
        {
            if (request == null)
            {
                return BadRequest("El cuerpo de la solicitud no puede ser nulo.");
            }
            var (variables,  resultado, mensaje) = await _variableRepository.GetAll(request.Offset, request.Limit);

            if (resultado == 0) 
            {
                return Ok(variables);
            }
            return StatusCode(500, new { ErrorCode = resultado, Message = mensaje });
        }

        // GET: api/Variables/5
        [HttpGet("{id:int}")]
        public async Task<ActionResult<VariableResponseDto>> GetVariable(int id) 
        {
            var (variableDto, resultado, mensaje) = await _variableRepository.GetById(id);

            if (resultado != 0) 
            {
                // PKG_VARIABLES_READ_BY_ID devuelve p_resultado = 10002 para "Variable no encontrada"
                if (resultado == 10002)
                {
                    return NotFound(new { ErrorCode = resultado, Message = mensaje });
                }
                return StatusCode(500, new { ErrorCode = resultado, Message = mensaje });
            }
            
            if (variableDto == null)
            {
                 return StatusCode(500, new { Message = "Error interno: El recurso debería existir pero no se pudo cargar." });
            }
            return Ok(variableDto);
        }

        // GET: api/Variables/name/VARIABLE_NAME
        [HttpGet("name/{name}")]
        public async Task<ActionResult<VariableResponseDto>> GetVariableByName(string name) 
        {
            var (variableDto, resultado, mensaje) = await _variableRepository.GetByName(name);

            if (resultado != 0) 
            {
                // PKG_VARIABLES_READ_BY_NAME devuelve p_resultado = 10004 para "Variable no encontrada"
                if (resultado == 10004)
                {
                    return NotFound(new { ErrorCode = resultado, Message = mensaje });
                }
                return StatusCode(500, new { ErrorCode = resultado, Message = mensaje });
            }
            
            if (variableDto == null)
            {
                return StatusCode(500, new { Message = "Error interno: El recurso debería existir pero no se pudo cargar." });
            }
            return Ok(variableDto);
        }

        // POST: api/Variables
        [HttpPost]
        public async Task<ActionResult<VariableResponseDto>> PostVariable([FromBody] VariableCreateRequestDto variableCreateDto)
        {
            var (idGenerado, resultado, mensaje) = await _variableRepository.Create(variableCreateDto);

            if (resultado == 0) 
            {
                var (variableDto, resultadoGet, mensajeGet) = await _variableRepository.GetById(idGenerado);
                if(resultadoGet == 0 && variableDto != null)
                {
                    return CreatedAtAction(nameof(GetVariable), new { id = idGenerado }, variableDto);
                }
                return StatusCode(500, new { ErrorCode = resultadoGet, Message = $"Variable creada con ID: {idGenerado} pero falló la recuperación. Detalle: {mensajeGet}" });
            }
            return BadRequest(new { ErrorCode = resultado, Message = mensaje });
        }

        // PUT: api/Variables/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutVariable(int id, [FromBody] VariableUpdateRequestDto variableUpdateDto)
        {
            if (id != variableUpdateDto.Id)
            {
                return BadRequest(new { Message = "El ID de la ruta no coincide con el ID del cuerpo de la solicitud." });
            }

            var (resultado, mensaje) = await _variableRepository.Update(variableUpdateDto);

            if (resultado == 0) 
            {
                return NoContent();
            }
            // PKG_VARIABLES_UPDATE devuelve p_resultado = 11005 para "Variable no encontrada"
            if (resultado == 11005)
            {
                return NotFound(new { ErrorCode = resultado, Message = mensaje });
            }
            return BadRequest(new { ErrorCode = resultado, Message = mensaje });
        }

        // DELETE: api/Variables/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteVariable(int id)
        {
            var (resultado, mensaje) = await _variableRepository.Delete(id);

            if (resultado == 0) 
            {
                return NoContent();
            }
            // PKG_VARIABLES_DELETE devuelve p_resultado = 12002 para "Variable no encontrada"
            if (resultado == 12002)
            {
                 return NotFound(new { ErrorCode = resultado, Message = mensaje });
            }
            return BadRequest(new { ErrorCode = resultado, Message = mensaje });
        }
    }
}