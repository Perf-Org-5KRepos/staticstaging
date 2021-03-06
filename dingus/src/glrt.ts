/**
 * The run-time support library for WebGL programs. This includes both
 * functions that the compiler emits calls to and utilities that the
 * programmer can invoke themselves.
 *
 * In ideal world, this wouldn't be coupled with the dingus, which is really
 * intended to be a UI. I'd like to refactor it into a separate `glrt`
 * component with its own `package.json` to indicate that it's core run-time
 * support for SCC programs. This should be possible with the "dependency"
 * feature slated for TypeScript 2.1:
 * https://github.com/Microsoft/TypeScript/issues/3469
 */

declare function require(name: string): any;

const pack = require('array-pack-2d');
const eye = require('eye-vector');
const mat4 = require('gl-mat4');
const normals = require('normals');

const bunny: Mesh = require('bunny');
const teapot: Mesh = require('teapot');
const snowden: Mesh = require('snowden');

/**
 * The type of the sample meshes we use.
 */
interface Mesh {
  positions: [number, number, number][];
  cells: [number, number, number][];
};

/**
 * Create a WebGL buffer object containing the given data.
 */
function make_buffer(gl: WebGLRenderingContext, data: number[][],
                     type: string, mode: number)
{
  // Initialize a buffer.
  let buf = gl.createBuffer();

  // Flatten the data to a packed array.
  let arr = pack(data, type);

  // Insert the data into the buffer.
  gl.bindBuffer(mode, buf);
  gl.bufferData(mode, arr, gl.STATIC_DRAW);

  return buf;
}

/**
 * Get the run-time values to expose to WebGL programs.
 */
export function runtime(gl: WebGLRenderingContext) {
  return {
    // Operations exposed to the language for getting data for meshes.
    mesh_indices(obj: Mesh) {
      return make_buffer(gl, obj.cells, 'uint16', gl.ELEMENT_ARRAY_BUFFER);
    },
    mesh_positions(obj: Mesh) {
      return make_buffer(gl, obj.positions, 'float32', gl.ARRAY_BUFFER);
    },
    mesh_normals(obj: Mesh) {
      let norm = normals.vertexNormals(obj.cells, obj.positions);
      return make_buffer(gl, norm, 'float32', gl.ARRAY_BUFFER);
    },
    mesh_size(obj: Mesh) {
      return obj.cells.length * obj.cells[0].length;
    },

    // And, similarly, a function for actually drawing a mesh. This takes the
    // indices buffer for the mesh and its size (in the number of scalars).
    draw_mesh(indices: WebGLBuffer, size: number) {
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indices);
      gl.drawElements(gl.TRIANGLES, size, gl.UNSIGNED_SHORT, 0);
    },

    // Sample meshes.
    bunny,
    teapot,
    snowden,

    // Matrix manipulation library.
    mat4,

    // Eye vector calculation.
    eye,

    // FIXME EXPERIMENTAL: Trying out textures.
    // Inspired by: https://twgljs.org
    a_texture() {
      let data = new Uint8ClampedArray([
        192,0,0,255,
        0,192,0,255,
        0,0,192,255,
        192,192,192,255,
      ]);

      let tex = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, tex);

      let img = new ImageData(data, 2, 2);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img);
      // gl.generateMipmaps(gl.TEXTURE_2D);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);

      gl.bindTexture(gl.TEXTURE_2D, null);  // Unbind.

      return tex;
    },

    // Create a buffer of values.
    float_array() {
      let arr = new Float32Array(arguments);

      let buf = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, buf);
      gl.bufferData(gl.ARRAY_BUFFER, arr, gl.STATIC_DRAW);

      return buf;
    },
  };
}
