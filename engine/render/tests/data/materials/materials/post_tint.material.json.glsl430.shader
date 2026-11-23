{
  "format": "factoria.shader/1",
  "engine": "0.35.2",
  "template": "1e9e617cc134cb3e70426cfbd8094c431d927c55e7a97a62ce35324a67af73d5",
  "slang": "glsl430",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "post",
  "programs": {
    "post": {
      "vs": "#version 430\n\nuniform vec4 fa_post_vs_params[1];\nlayout(location = 0) in vec2 pos;\nlayout(location = 0) out vec2 fa_uv;\n\nvoid main()\n{\n    gl_Position = vec4(pos, 0.0, 1.0);\n    float _33 = pos.y * 0.5;\n    fa_uv = vec2((pos.x * 0.5) + 0.5, mix(0.5 - _33, 0.5 + _33, fa_post_vs_params[0].x));\n}\n\n",
      "fs": "#version 430\n\nstruct PostInput\n{\n    vec2 uv;\n    vec2 texel;\n    vec2 size;\n    float time;\n};\n\nstruct PostSurface\n{\n    vec4 color;\n};\n\nuniform vec4 fa_post_params[4];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_scene_fa_scene_smp;\n\nlayout(location = 0) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec2 fa_flip_uv(vec2 s)\n{\n    return vec2(s.x, mix(s.y, 1.0 - s.y, fa_post_params[0].x));\n}\n\nvec4 fa_scene_color(vec2 uv)\n{\n    vec2 _68 = fa_post_params[2].zw * 0.5;\n    vec2 param = (clamp(uv, _68, vec2(1.0) - _68) * fa_post_params[1].zw) + fa_post_params[1].xy;\n    return textureLod(fa_scene_fa_scene_smp, fa_flip_uv(param), 0.0);\n}\n\nvec3 fa_scene_rgb(vec3 c)\n{\n    if (fa_post_params[0].y < 0.5)\n    {\n        return c;\n    }\n    return mix(c * vec3(0.077399380505084991455078125), pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), step(vec3(0.040449999272823333740234375), c));\n}\n\nvoid post(PostInput i, inout PostSurface s)\n{\n    vec3 param = fa_material[0].xyz;\n    vec4 _160 = s.color;\n    vec3 _162 = _160.xyz * fa_scene_rgb(param);\n    s.color.x = _162.x;\n    s.color.y = _162.y;\n    s.color.z = _162.z;\n}\n\nfloat fa_sane(float x)\n{\n    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u)\n    {\n        return 0.0;\n    }\n    return clamp(x, 0.0, 65504.0);\n}\n\nvoid main()\n{\n    vec2 param = fa_uv;\n    vec2 _175 = fa_flip_uv(param);\n    vec2 param_1 = _175;\n    vec4 _194 = fa_scene_color(param_1);\n    vec4 _246 = _194;\n    PostInput param_2 = PostInput(_175, fa_post_params[2].zw, fa_post_params[2].xy, fa_post_params[3].x);\n    PostSurface param_3 = PostSurface(_194);\n    post(param_2, param_3);\n    _246 = param_3.color;\n    float _210;\n    if (((floatBitsToUint(param_3.color.w) >> 23u) & 255u) == 255u)\n    {\n        _210 = 1.0;\n    }\n    else\n    {\n        _210 = clamp(_246.w, 0.0, 1.0);\n    }\n    float param_4 = _246.x;\n    float param_5 = _246.y;\n    float param_6 = _246.z;\n    fa_frag_color = vec4(fa_sane(param_4), fa_sane(param_5), fa_sane(param_6), _210);\n}\n\n",
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
            "size": 16,
            "struct_name": "fa_post_vs_params",
            "inst_name": "_51",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_post_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 64,
            "struct_name": "fa_post_params",
            "inst_name": "_51",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_post_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_152",
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
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_scene",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_scene_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_scene_fa_scene_smp",
            "view_name": "fa_scene",
            "sampler_name": "fa_scene_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_scene_fa_scene_smp"
          }
        ]
      }
    }
  }
}
