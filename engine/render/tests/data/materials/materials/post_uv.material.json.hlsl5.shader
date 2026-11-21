{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "1e9e617cc134cb3e70426cfbd8094c431d927c55e7a97a62ce35324a67af73d5",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "post",
  "programs": {
    "post": {
      "vs": "cbuffer fa_post_vs_params : register(b0)\n{\n    float4 _51_fa_flip : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 pos;\nstatic float2 fa_uv;\n\nstruct SPIRV_Cross_Input\n{\n    float2 pos : TEXCOORD0;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 fa_uv : TEXCOORD0;\n    float4 gl_Position : SV_Position;\n};\n\nvoid vert_main()\n{\n    gl_Position = float4(pos, 0.0f, 1.0f);\n    float _33 = pos.y * 0.5f;\n    fa_uv = float2((pos.x * 0.5f) + 0.5f, lerp(0.5f - _33, 0.5f + _33, _51_fa_flip.x));\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    pos = stage_input.pos;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_uv = fa_uv;\n    return stage_output;\n}\n",
      "fs": "struct PostInput\n{\n    float2 uv;\n    float2 texel;\n    float2 size;\n    float time;\n};\n\nstruct PostSurface\n{\n    float4 color;\n};\n\ncbuffer fa_post_params : register(b1)\n{\n    float4 _45_fa_a : packoffset(c0);\n    float4 _45_fa_rc : packoffset(c1);\n    float4 _45_fa_size : packoffset(c2);\n    float4 _45_fa_time : packoffset(c3);\n};\n\nTexture2D<float4> fa_scene : register(t0);\nSamplerState fa_scene_smp : register(s0);\n\nstatic float2 fa_uv;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float2 fa_uv : TEXCOORD0;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat2 fa_flip_uv(float2 s)\n{\n    return float2(s.x, lerp(s.y, 1.0f - s.y, _45_fa_a.x));\n}\n\nfloat4 fa_scene_color(float2 uv)\n{\n    float2 _62 = _45_fa_size.zw * 0.5f;\n    float2 param = (clamp(uv, _62, 1.0f.xx - _62) * _45_fa_rc.zw) + _45_fa_rc.xy;\n    return fa_scene.SampleLevel(fa_scene_smp, fa_flip_uv(param), 0.0f);\n}\n\nvoid post(PostInput i, inout PostSurface s)\n{\n    s.color.x = i.uv.x;\n    s.color.y = i.uv.y;\n    s.color.z = clamp(i.time * 0.25f, 0.0f, 1.0f);\n}\n\nfloat fa_sane(float x)\n{\n    if (((asuint(x) >> 23u) & 255u) == 255u)\n    {\n        return 0.0f;\n    }\n    return clamp(x, 0.0f, 65504.0f);\n}\n\nvoid frag_main()\n{\n    float2 param = fa_uv;\n    float2 _136 = fa_flip_uv(param);\n    float2 param_1 = _136;\n    float4 _154 = fa_scene_color(param_1);\n    float4 _207 = _154;\n    PostInput _206 = { _136, _45_fa_size.zw, _45_fa_size.xy, _45_fa_time.x };\n    PostInput param_2 = _206;\n    PostSurface _209 = { _154 };\n    PostSurface param_3 = _209;\n    post(param_2, param_3);\n    _207 = param_3.color;\n    float _171;\n    if (((asuint(param_3.color.w) >> 23u) & 255u) == 255u)\n    {\n        _171 = 1.0f;\n    }\n    else\n    {\n        _171 = clamp(_207.w, 0.0f, 1.0f);\n    }\n    float param_4 = _207.x;\n    float param_5 = _207.y;\n    float param_6 = _207.z;\n    fa_frag_color = float4(fa_sane(param_4), fa_sane(param_5), fa_sane(param_6), _171);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_uv = stage_input.fa_uv;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_post_vs_params",
            "inst_name": "_51",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 64,
            "struct_name": "fa_post_params",
            "inst_name": "_45",
            "hlsl_register_b_n": 1
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
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_scene_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
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
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
