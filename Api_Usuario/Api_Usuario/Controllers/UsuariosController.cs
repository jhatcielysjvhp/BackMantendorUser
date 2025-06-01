using Microsoft.AspNetCore.Mvc;
using Api_Sistema_Usuarios.Models;
using Api_Sistema_Usuarios.Models.Dtos;
using Api_Sistema_Usuarios.Models.Dtos.Input; 
using Api_Sistema_Usuarios.Models.Dtos.Output;
using Api_Sistema_Usuarios.Repositories;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace Api_Sistema_Usuarios.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsuariosController : ControllerBase
    {
        private readonly UsuarioRepository _usuarioRepository;

        public UsuariosController(UsuarioRepository usuarioRepository)
        {
            _usuarioRepository = usuarioRepository;
        }

       

        // POST: api/Usuarios/list
        [HttpPost("list")]
        public async Task<ActionResult<IEnumerable<UsuarioResponseDto>>> ListUsuarios([FromBody] GetUsuariosRequestDto request)
        {
            if (request == null)
            {
                return BadRequest("El cuerpo de la solicitud no puede ser nulo.");
            }
            var (usuarios, resultado, mensaje) = await _usuarioRepository.GetAll(request.Offset, request.Limit);

            if (resultado == 0)
            {
               return Ok(usuarios);
            }
            return StatusCode(500, new { ErrorCode = resultado, Message = mensaje });
        }

        // GET: api/Usuarios/id
        [HttpGet("{id}")]
        public async Task<ActionResult<UsuarioResponseDto>> GetUsuario(int id)
        {
            var (usuarioDto, resultado, mensaje) = await _usuarioRepository.GetById(id);

            if (resultado != 0)
            {
                // PKG_USUARIOS_READ_BY_ID devuelve p_resultado = 6002 para "Usuario no encontrado"
                if (resultado == 6002) 
                {
                    return NotFound(new { ErrorCode = resultado, Message = mensaje });
                }
                return StatusCode(500, new { ErrorCode = resultado, Message = mensaje });
            }
            
            if (usuarioDto == null)
            {
                return StatusCode(500, new { Message = "Error interno: El recurso debería existir pero no se pudo cargar." });
            }
            return Ok(usuarioDto);
        }

        // POST: api/Usuarios
        [HttpPost]
        public async Task<ActionResult<UsuarioResponseDto>> PostUsuario([FromBody] UsuarioCreateRequestDto usuarioCreateDto)
        {
            var (idGenerado, resultado, mensaje) = await _usuarioRepository.Create(usuarioCreateDto);

            if (resultado == 0)
            {
                var (usuarioDto, resultadoGet, mensajeGet) = await _usuarioRepository.GetById(idGenerado);
                if (resultadoGet == 0 && usuarioDto != null)
                {
                    return CreatedAtAction(nameof(GetUsuario), new { id = idGenerado }, usuarioDto);
                }
                return StatusCode(500, new { ErrorCode = resultadoGet, Message = $"Usuario creado con ID: {idGenerado} pero falló la recuperación. Detalle: {mensajeGet}" });
            }
            return BadRequest(new { ErrorCode = resultado, Message = mensaje });
        }

        // PUT: api/Usuarios/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutUsuario(int id, [FromBody] UsuarioUpdateRequestDto usuarioUpdateDto)
        {
            if (id != usuarioUpdateDto.Id)
            {
                return BadRequest(new { Message = "El ID de la ruta no coincide con el ID del cuerpo de la solicitud." });
            }

            var (resultado, mensaje) = await _usuarioRepository.Update(usuarioUpdateDto);

            if (resultado == 0)
            {
                return NoContent();
            }
            // PKG_USUARIOS_UPDATE devuelve p_resultado = 7009 para "Usuario no encontrado"
            if (resultado == 7009)
            {
                return NotFound(new { ErrorCode = resultado, Message = mensaje });
            }
            return BadRequest(new { ErrorCode = resultado, Message = mensaje });
        }

        // DELETE: api/Usuarios/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUsuario(int id)
        {
            var (resultado, mensaje) = await _usuarioRepository.Delete(id);

            if (resultado == 0)
            {
                return NoContent();
            }
            // PKG_USUARIOS_DELETE devuelve p_resultado = 8002 para "Usuario no encontrado"
            if (resultado == 8002)
            {
                return NotFound(new { ErrorCode = resultado, Message = mensaje });
            }
            return BadRequest(new { ErrorCode = resultado, Message = mensaje });
        }
    }
}