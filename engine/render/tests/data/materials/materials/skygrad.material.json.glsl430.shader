{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "3e2ab04520b9dfea7aed47b5f8c67dace661b6200fc615b2b53570e4e4b3c03a",
  "slang": "glsl430",
  "params": [
    "ground",
    "zenith"
  ],
  "textures": [],
  "kind": "sky",
  "programs": {
    "sky": {
      "vs": "#version 430\n\nuniform vec4 sky_vs_params[5];\nlayout(location = 0) in vec2 pos;\nlayout(location = 0) out vec3 ray_dir;\n\nvoid main()\n{\n    vec4 _23 = vec4(pos, 1.0, 1.0);\n    gl_Position = _23;\n    vec4 _39 = mat4(sky_vs_params[0], sky_vs_params[1], sky_vs_params[2], sky_vs_params[3]) * _23;\n    ray_dir = (_39.xyz / vec3(_39.w)) - sky_vs_params[4].xyz;\n}\n\n",
      "fs": "#version 430\n\nstruct SkyInput\n{\n    vec3 dir;\n    vec3 sun_dir;\n    float time;\n};\n\nstruct SkySurface\n{\n    vec3 color;\n};\n\nuniform vec4 fa_material[2];\nuniform vec4 sky_fs_params[5];\nlayout(location = 0) in vec3 ray_dir;\nlayout(location = 0) out vec4 frag_color;\n\nvoid sky(SkyInput i, inout SkySurface s)\n{\n    s.color = mix(fa_material[0].xyz, fa_material[1].xyz, vec3(clamp((i.dir.y * 0.5) + 0.5, 0.0, 1.0)));\n}\n\nvoid main()\n{\n    vec3 _50 = normalize(ray_dir);\n    SkyInput param = SkyInput(_50, sky_fs_params[2].xyz, sky_fs_params[3].x);\n    SkySurface param_1 = SkySurface(mix(sky_fs_params[1].xyz, sky_fs_params[0].xyz, vec3(pow(clamp(_50.y, 0.0, 1.0), 0.550000011920928955078125))));\n    sky(param, param_1);\n    frag_color = vec4(param_1.color, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "pos"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 80,
            "struct_name": "sky_vs_params",
            "inst_name": "_31",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 5,
                "offset": 0,
                "glsl_name": "sky_vs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_22",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 80,
            "struct_name": "sky_fs_params",
            "inst_name": "_64",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 5,
                "offset": 0,
                "glsl_name": "sky_fs_params"
              }
            ]
          }
        ]
      }
    }
  }
}
