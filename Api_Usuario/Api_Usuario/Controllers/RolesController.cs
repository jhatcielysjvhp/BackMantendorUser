using Microsoft.AspNetCore.Mvc;
using Api_Sistema_Usuarios.Models.Dtos.Input; 
using Api_Sistema_Usuarios.Models.Dtos.Output;
using Api_Sistema_Usuarios.Repositories;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace Api_Sistema_Usuarios.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RolesController : ControllerBase
    {
        private readonly RoleRepository _roleRepository;

        public RolesController(RoleRepository roleRepository)
        {
            _roleRepository = roleRepository;
        }

        [HttpPost("list")]
        public async Task<ActionResult<IEnumerable<RoleResponseDto>>> ListRoles([FromBody] GetRolesRequestDto request)
        {
            if (request == null)
            {
                return BadRequest("El cuerpo de la solicitud no puede ser nulo.");
            }

            var (roles, totalRegistros, resultado, mensaje) = await _roleRepository.GetAll(request.Offset, request.Limit);

            if (resultado == 0)
            {
                Response.Headers.Append("X-Total-Count", totalRegistros.ToString());
                return Ok(roles);
            }
            // Si resultado no es 0, es un error del SP (probablemente SQL o configuraci�n)
            return StatusCode(500, new { ErrorCode = resultado, Message = mensaje });
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<RoleResponseDto>> GetRole(int id)
        {
            var (roleDto, resultado, mensaje) = await _roleRepository.GetById(id);

            if (resultado != 0)
            {
                // PKG_ROLES_READ_BY_ID devuelve p_resultado = 2002 para "Rol no encontrado"
                if (resultado == 2002) 
                {
                    return NotFound(new { ErrorCode = resultado, Message = mensaje });
                }
                return StatusCode(500, new { ErrorCode = resultado, Message = mensaje }); // Otro error del SP
            }

            // resultado == 0, SP indica �xito.
            if (roleDto == null)
            {
                // Situaci�n inesperada: SP dice �xito (resultado=0) pero no hay DTO.
                // Podr�a ser un problema de mapeo o el SP no devolvi� el result set esperado.
                return StatusCode(500, new { Message = "Error interno: El recurso deber�a existir pero no se pudo cargar." });
            }

            return Ok(roleDto);
        }

        [HttpPost]
        public async Task<ActionResult<RoleResponseDto>> PostRole([FromBody] RoleCreateRequestDto roleCreateDto)
        {
            var (idGenerado, resultado, mensaje) = await _roleRepository.Create(roleCreateDto);

            if (resultado == 0)
            {
                var (roleDto, resultadoGet, mensajeGet) = await _roleRepository.GetById(idGenerado);
                if (resultadoGet == 0 && roleDto != null)
                {
                    return CreatedAtAction(nameof(GetRole), new { id = idGenerado }, roleDto);
                }
                // Si GetById falla despu�s de una creaci�n exitosa.
                return StatusCode(500, new { ErrorCode = resultadoGet, Message = $"Rol creado con ID: {idGenerado} pero fall� la recuperaci�n. Detalle: {mensajeGet}" });
            }
            // Errores de validaci�n del SP (ej. nombre duplicado, nombre vac�o) u otros errores de creaci�n.
            return BadRequest(new { ErrorCode = resultado, Message = mensaje });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutRole(int id, [FromBody] RoleUpdateRequestDto roleUpdateDto)
        {
            if (id != roleUpdateDto.Id)
            {
                return BadRequest(new { Message = "El ID de la ruta no coincide con el ID del cuerpo de la solicitud." });
            }

            var (resultado, mensaje) = await _roleRepository.Update(roleUpdateDto);

            if (resultado == 0)
            {
                return NoContent(); // Actualizaci�n exitosa
            }

            // PKG_ROLES_UPDATE devuelve p_resultado = 3004 para "Rol no encontrado"
            if (resultado == 3004)
            {
                return NotFound(new { ErrorCode = resultado, Message = mensaje });
            }
            
            // Otros errores de validaci�n del SP (ej. nombre duplicado, ID inv�lido)
            return BadRequest(new { ErrorCode = resultado, Message = mensaje });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRole(int id)
        {
            var (resultado, mensaje) = await _roleRepository.Delete(id);

            if (resultado == 0)
            {
                return NoContent(); // Eliminaci�n exitosa
            }

            // PKG_ROLES_DELETE:
            // p_resultado = 4002 es "Rol no encontrado"
            // p_resultado = 4003 es "No se puede eliminar el rol. Tiene ... usuarios asociados"
            if (resultado == 4002)
            {
                return NotFound(new { ErrorCode = resultado, Message = mensaje });
            }
            if (resultado == 4003) // Conflicto, no se puede eliminar
            {
                return Conflict(new { ErrorCode = resultado, Message = mensaje });
            }
            
            // Otros errores (ej. ID inv�lido)
            return BadRequest(new { ErrorCode = resultado, Message = mensaje });
        }
    }
}