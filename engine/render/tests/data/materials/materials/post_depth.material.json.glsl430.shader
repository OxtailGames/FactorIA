{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "d03c1c7f934d4bdc20c513c6cb4bc09d11d7167b51a10ca9dcb59b504997591f",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "post",
  "programs": {
    "post": {
      "vs": "#version 430\n\nuniform vec4 fa_post_vs_params[1];\nlayout(location = 0) in vec2 pos;\nlayout(location = 0) out vec2 fa_uv;\n\nvoid main()\n{\n    gl_Position = vec4(pos, 0.0, 1.0);\n    float _33 = pos.y * 0.5;\n    fa_uv = vec2((pos.x * 0.5) + 0.5, mix(0.5 - _33, 0.5 + _33, fa_post_vs_params[0].x));\n}\n\n",
      "fs": "#version 430\n\nstruct PostInput\n{\n    vec2 uv;\n    vec2 texel;\n    vec2 size;\n    float time;\n};\n\nstruct PostSurface\n{\n    vec4 color;\n};\n\nuniform vec4 fa_post_params[4];\nlayout(binding = 0) uniform sampler2D fa_scene_fa_scene_smp;\nlayout(binding = 1) uniform sampler2D fa_prepass_fa_prepass_smp;\n\nlayout(location = 0) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec2 fa_flip_uv(vec2 s)\n{\n    return vec2(s.x, mix(s.y, 1.0 - s.y, fa_post_params[0].x));\n}\n\nvec4 fa_scene_color(vec2 uv)\n{\n    vec2 param = (clamp(uv, vec2(0.0), vec2(1.0)) * fa_post_params[1].zw) + fa_post_params[1].xy;\n    return textureLod(fa_scene_fa_scene_smp, fa_flip_uv(param), 0.0);\n}\n\nvec4 fa_prepass_at(vec2 uv)\n{\n    vec2 param = clamp(uv, vec2(0.0), vec2(1.0));\n    return textureLod(fa_prepass_fa_prepass_smp, fa_flip_uv(param), 0.0);\n}\n\nfloat fa_depth(vec2 uv)\n{\n    vec2 param = uv;\n    vec4 _115 = fa_prepass_at(param);\n    float _122;\n    if (_115.w > 0.5)\n    {\n        _122 = _115.x;\n    }\n    else\n    {\n        _122 = 60000.0;\n    }\n    return _122;\n}\n\nvec3 fa_normal(vec2 uv)\n{\n    vec2 param = uv;\n    vec4 _135 = fa_prepass_at(param);\n    if (_135.w < 0.5)\n    {\n        return vec3(0.0);\n    }\n    float _148 = _135.y;\n    float _155 = (1.0 - abs(_148)) - abs(_135.z);\n    vec3 n = vec3(_148, _135.z, _155);\n    if (_155 < 0.0)\n    {\n        vec3 _164 = n;\n        vec2 _179 = (vec2(1.0) - abs(_164.yx)) * vec2((_164.x >= 0.0) ? 1.0 : (-1.0), (_164.y >= 0.0) ? 1.0 : (-1.0));\n        vec3 _328 = _164;\n        _328.x = _179.x;\n        _328.y = _179.y;\n        n = _328;\n    }\n    return normalize(n);\n}\n\nvoid post(PostInput i, inout PostSurface s)\n{\n    vec2 param = i.uv;\n    vec2 param_1 = i.uv;\n    vec3 _212 = fa_normal(param_1);\n    s.color.x = clamp(fa_depth(param) * 0.0500000007450580596923828125, 0.0, 1.0);\n    s.color.y = (_212.x * 0.5) + 0.5;\n    s.color.z = (_212.y * 0.5) + 0.5;\n}\n\nfloat fa_sane(float x)\n{\n    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u)\n    {\n        return 0.0;\n    }\n    return clamp(x, 0.0, 65504.0);\n}\n\nvoid main()\n{\n    vec2 param = fa_uv;\n    vec2 _237 = fa_flip_uv(param);\n    vec2 param_1 = _237;\n    vec4 _257 = fa_scene_color(param_1);\n    vec4 _305 = _257;\n    PostInput param_2 = PostInput(_237, fa_post_params[2].zw, fa_post_params[2].xy, fa_post_params[3].x);\n    PostSurface param_3 = PostSurface(_257);\n    post(param_2, param_3);\n    _305 = param_3.color;\n    float _272;\n    if (((floatBitsToUint(param_3.color.w) >> 23u) & 255u) == 255u)\n    {\n        _272 = 1.0;\n    }\n    else\n    {\n        _272 = clamp(_305.w, 0.0, 1.0);\n    }\n    float param_4 = _305.x;\n    float param_5 = _305.y;\n    float param_6 = _305.z;\n    fa_frag_color = vec4(fa_sane(param_4), fa_sane(param_5), fa_sane(param_6), _272);\n}\n\n",
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
            "inst_name": "_57",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_post_params"
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
              "slot": 1,
              "stage": "fragment",
              "name": "fa_prepass",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_scene_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_prepass_smp",
            "sampler_type": "nonfiltering"
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
            "name": "fa_prepass_fa_prepass_smp",
            "view_name": "fa_prepass",
            "sampler_name": "fa_prepass_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_prepass_fa_prepass_smp"
          }
        ]
      }
    }
  }
}
