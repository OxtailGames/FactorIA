{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "b6c305c04441712b1ad265cf05ea47a8046d58f7c1488095fd9dd43a43af561f",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "post",
  "programs": {
    "post": {
      "vs": "#version 430\n\nuniform vec4 fa_post_vs_params[1];\nlayout(location = 0) in vec2 pos;\nlayout(location = 0) out vec2 fa_uv;\n\nvoid main()\n{\n    gl_Position = vec4(pos, 0.0, 1.0);\n    float _33 = pos.y * 0.5;\n    fa_uv = vec2((pos.x * 0.5) + 0.5, mix(0.5 - _33, 0.5 + _33, fa_post_vs_params[0].x));\n}\n\n",
      "fs": "#version 430\n\nstruct PostInput\n{\n    vec2 uv;\n    vec2 texel;\n    vec2 size;\n    float time;\n};\n\nstruct PostSurface\n{\n    vec4 color;\n};\n\nuniform vec4 fa_post_params[4];\nlayout(binding = 0) uniform sampler2D fa_scene_fa_scene_smp;\n\nlayout(location = 0) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec2 fa_flip_uv(vec2 s)\n{\n    return vec2(s.x, mix(s.y, 1.0 - s.y, fa_post_params[0].x));\n}\n\nvec4 fa_scene_color(vec2 uv)\n{\n    vec2 _62 = fa_post_params[2].zw * 0.5;\n    vec2 param = (clamp(uv, _62, vec2(1.0) - _62) * fa_post_params[1].zw) + fa_post_params[1].xy;\n    return textureLod(fa_scene_fa_scene_smp, fa_flip_uv(param), 0.0);\n}\n\nvoid post(PostInput i, PostSurface s)\n{\n}\n\nfloat fa_sane(float x)\n{\n    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u)\n    {\n        return 0.0;\n    }\n    return clamp(x, 0.0, 65504.0);\n}\n\nvoid main()\n{\n    vec2 param = fa_uv;\n    vec2 _117 = fa_flip_uv(param);\n    vec2 param_1 = _117;\n    vec4 _136 = fa_scene_color(param_1);\n    vec4 _189 = _136;\n    PostInput param_2 = PostInput(_117, fa_post_params[2].zw, fa_post_params[2].xy, fa_post_params[3].x);\n    PostSurface param_3 = PostSurface(_136);\n    post(param_2, param_3);\n    _189 = param_3.color;\n    float _153;\n    if (((floatBitsToUint(param_3.color.w) >> 23u) & 255u) == 255u)\n    {\n        _153 = 1.0;\n    }\n    else\n    {\n        _153 = clamp(_189.w, 0.0, 1.0);\n    }\n    float param_4 = _189.x;\n    float param_5 = _189.y;\n    float param_6 = _189.z;\n    fa_frag_color = vec4(fa_sane(param_4), fa_sane(param_5), fa_sane(param_6), _153);\n}\n\n",
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
            "inst_name": "_45",
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
