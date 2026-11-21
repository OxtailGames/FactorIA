{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "1e9e617cc134cb3e70426cfbd8094c431d927c55e7a97a62ce35324a67af73d5",
  "slang": "glsl430",
  "params": [
    "keep",
    "mark"
  ],
  "textures": [],
  "kind": "post",
  "programs": {
    "post": {
      "vs": "#version 430\n\nuniform vec4 fa_post_vs_params[1];\nlayout(location = 0) in vec2 pos;\nlayout(location = 0) out vec2 fa_uv;\n\nvoid main()\n{\n    gl_Position = vec4(pos, 0.0, 1.0);\n    float _33 = pos.y * 0.5;\n    fa_uv = vec2((pos.x * 0.5) + 0.5, mix(0.5 - _33, 0.5 + _33, fa_post_vs_params[0].x));\n}\n\n",
      "fs": "#version 430\n\nstruct PostInput\n{\n    vec2 uv;\n    vec2 texel;\n    vec2 size;\n    float time;\n};\n\nstruct PostSurface\n{\n    vec4 color;\n};\n\nuniform vec4 fa_post_params[4];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_scene_fa_scene_smp;\nlayout(binding = 1) uniform sampler2D fa_history_tex_fa_scene_smp;\n\nlayout(location = 0) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec2 fa_flip_uv(vec2 s)\n{\n    return vec2(s.x, mix(s.y, 1.0 - s.y, fa_post_params[0].x));\n}\n\nvec4 fa_scene_color(vec2 uv)\n{\n    vec2 _65 = fa_post_params[2].zw * 0.5;\n    vec2 param = (clamp(uv, _65, vec2(1.0) - _65) * fa_post_params[1].zw) + fa_post_params[1].xy;\n    return textureLod(fa_scene_fa_scene_smp, fa_flip_uv(param), 0.0);\n}\n\nvec4 fa_history(vec2 uv)\n{\n    if (!(fa_post_params[0].z > 0.5))\n    {\n        vec2 param = uv;\n        return fa_scene_color(param);\n    }\n    vec2 _115 = fa_post_params[2].zw * 0.5;\n    vec2 param_1 = clamp(uv, _115, vec2(1.0) - _115);\n    return textureLod(fa_history_tex_fa_scene_smp, fa_flip_uv(param_1), 0.0);\n}\n\nvoid post(PostInput i, inout PostSurface s)\n{\n    vec2 param = i.uv;\n    vec4 _156 = s.color;\n    vec3 _166 = max(_156.xyz, fa_history(param).xyz * fa_material[0].x);\n    s.color.x = _166.x;\n    s.color.y = _166.y;\n    s.color.z = _166.z;\n    bool _176 = fa_material[1].x > 0.5;\n    bool _182;\n    if (_176)\n    {\n        _182 = fa_post_params[0].z > 0.5;\n    }\n    else\n    {\n        _182 = _176;\n    }\n    if (_182)\n    {\n        s.color.x = 1.0;\n        s.color.y = 0.0;\n        s.color.z = 0.0;\n    }\n}\n\nfloat fa_sane(float x)\n{\n    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u)\n    {\n        return 0.0;\n    }\n    return clamp(x, 0.0, 65504.0);\n}\n\nvoid main()\n{\n    vec2 param = fa_uv;\n    vec2 _197 = fa_flip_uv(param);\n    vec2 param_1 = _197;\n    vec4 _216 = fa_scene_color(param_1);\n    vec4 _267 = _216;\n    PostInput param_2 = PostInput(_197, fa_post_params[2].zw, fa_post_params[2].xy, fa_post_params[3].x);\n    PostSurface param_3 = PostSurface(_216);\n    post(param_2, param_3);\n    _267 = param_3.color;\n    float _232;\n    if (((floatBitsToUint(param_3.color.w) >> 23u) & 255u) == 255u)\n    {\n        _232 = 1.0;\n    }\n    else\n    {\n        _232 = clamp(_267.w, 0.0, 1.0);\n    }\n    float param_4 = _267.x;\n    float param_5 = _267.y;\n    float param_6 = _267.z;\n    fa_frag_color = vec4(fa_sane(param_4), fa_sane(param_5), fa_sane(param_6), _232);\n}\n\n",
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
            "inst_name": "_48",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_162",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "fa_history_tex",
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
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_history_tex_fa_scene_smp",
            "view_name": "fa_history_tex",
            "sampler_name": "fa_scene_smp",
            "view_slot": 6,
            "sampler_slot": 0,
            "glsl_name": "fa_history_tex_fa_scene_smp"
          }
        ]
      }
    }
  }
}
