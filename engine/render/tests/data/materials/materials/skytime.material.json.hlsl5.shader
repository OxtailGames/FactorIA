{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "3e2ab04520b9dfea7aed47b5f8c67dace661b6200fc615b2b53570e4e4b3c03a",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sky",
  "programs": {
    "sky": {
      "vs": "cbuffer sky_vs_params : register(b0)\n{\n    row_major float4x4 _31_inv_view_proj : packoffset(c0);\n    float4 _31_cam_pos : packoffset(c4);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 pos;\nstatic float3 ray_dir;\n\nstruct SPIRV_Cross_Input\n{\n    float2 pos : TEXCOORD0;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 ray_dir : TEXCOORD0;\n    float4 gl_Position : SV_Position;\n};\n\nvoid vert_main()\n{\n    float4 _23 = float4(pos, 1.0f, 1.0f);\n    gl_Position = _23;\n    float4 _39 = mul(_23, _31_inv_view_proj);\n    ray_dir = (_39.xyz / _39.w.xxx) - _31_cam_pos.xyz;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    pos = stage_input.pos;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.ray_dir = ray_dir;\n    return stage_output;\n}\n",
      "fs": "struct SkyInput\n{\n    float3 dir;\n    float3 sun_dir;\n    float time;\n};\n\nstruct SkySurface\n{\n    float3 color;\n};\n\ncbuffer sky_fs_params : register(b1)\n{\n    float4 _61_sky_color : packoffset(c0);\n    float4 _61_horizon_color : packoffset(c1);\n    float4 _61_fa_sun : packoffset(c2);\n    float4 _61_fa_time : packoffset(c3);\n    float4 _61_fa_cspace : packoffset(c4);\n};\n\n\nstatic float3 ray_dir;\nstatic float4 frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 ray_dir : TEXCOORD0;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nvoid sky(SkyInput i, inout SkySurface s)\n{\n    s.color = float3(0.5f + (0.5f * sin(i.time * 3.0f)), 0.25f * frac(i.time), 0.25f);\n}\n\nvoid frag_main()\n{\n    float3 _41 = normalize(ray_dir);\n    SkyInput _104 = { _41, _61_fa_sun.xyz, _61_fa_time.x };\n    SkyInput param = _104;\n    SkySurface _107 = { lerp(_61_horizon_color.xyz, _61_sky_color.xyz, pow(clamp(_41.y, 0.0f, 1.0f), 0.550000011920928955078125f).xxx) };\n    SkySurface param_1 = _107;\n    sky(param, param_1);\n    frag_color = float4(param_1.color, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    ray_dir = stage_input.ray_dir;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 80,
            "struct_name": "sky_vs_params",
            "inst_name": "_31",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 80,
            "struct_name": "sky_fs_params",
            "inst_name": "_61",
            "hlsl_register_b_n": 1
          }
        ]
      }
    }
  },
  "animated": true
}
