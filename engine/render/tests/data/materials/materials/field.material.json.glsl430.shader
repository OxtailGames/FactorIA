{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "glsl430",
  "params": [
    "blue"
  ],
  "textures": [
    "src"
  ],
  "kind": "compute",
  "workgroupSize": [
    8,
    8,
    1
  ],
  "buffers": [],
  "images": [
    {
      "name": "count",
      "binding": 0,
      "format": "r32f",
      "access": "readWrite",
      "width": 16,
      "height": 16
    },
    {
      "name": "field",
      "binding": 1,
      "format": "rgba8",
      "access": "write",
      "width": 16,
      "height": 16
    }
  ],
  "programs": {
    "compute": {
      "cs": "#version 430\nlayout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;\n\nstruct ComputeInput\n{\n    uvec3 global_id;\n    uvec3 local_id;\n    uvec3 group_id;\n    uint local_index;\n};\n\nuniform vec4 fa_material[1];\nlayout(binding = 1, rgba8) uniform writeonly image2D field;\nlayout(binding = 0, r32f) uniform image2D count;\nlayout(binding = 0) uniform sampler2D src_src_smp;\n\nvoid compute(ComputeInput i)\n{\n    ivec2 _24 = ivec2(i.global_id.xy);\n    ivec2 _31 = imageSize(field);\n    int _36 = _24.x;\n    bool _39 = _36 >= _31.x;\n    bool _49;\n    if (!_39)\n    {\n        _49 = _24.y >= _31.y;\n    }\n    else\n    {\n        _49 = _39;\n    }\n    if (_49)\n    {\n        return;\n    }\n    imageStore(field, _24, vec4(float(_36 * 16) * 0.0039215688593685626983642578125, float(_24.y * 16) * 0.0039215688593685626983642578125, fa_material[0].x * textureLod(src_src_smp, vec2(0.5), 0.0).w, 1.0));\n    imageStore(count, _24, vec4(imageLoad(count, _24).x + 1.0, 0.0, 0.0, 0.0));\n}\n\nvoid main()\n{\n    ComputeInput param = ComputeInput(gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex);\n    compute(param);\n}\n\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main"
        },
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "compute",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_89",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "storage_image": {
              "slot": 0,
              "stage": "compute",
              "name": "count",
              "type": "2d",
              "access_format": "R32F",
              "writeonly": false,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_image": {
              "slot": 1,
              "stage": "compute",
              "name": "field",
              "type": "2d",
              "access_format": "RGBA8",
              "writeonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "compute",
              "name": "src",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "compute",
            "name": "src_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "compute",
            "name": "src_src_smp",
            "view_name": "src",
            "sampler_name": "src_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "src_src_smp"
          }
        ]
      }
    }
  }
}
