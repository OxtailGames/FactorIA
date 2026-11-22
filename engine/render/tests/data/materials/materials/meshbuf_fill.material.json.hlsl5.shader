{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "hlsl5",
  "params": [
    "count",
    "hide",
    "spacing"
  ],
  "textures": [],
  "kind": "compute",
  "workgroupSize": [
    64,
    1,
    1
  ],
  "buffers": [
    {
      "name": "points",
      "binding": 0,
      "stride": 32,
      "access": "readWrite",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "compute": {
      "cs": "struct ComputeInput\n{\n    uint3 global_id;\n    uint3 local_id;\n    uint3 group_id;\n    uint local_index;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstatic const uint3 gl_WorkGroupSize = uint3(64u, 1u, 1u);\n\ncbuffer fa_material : register(b0)\n{\n    float _26_count : packoffset(c0);\n    float _26_fa_pad0 : packoffset(c0.y);\n    float _26_fa_pad1 : packoffset(c0.z);\n    float _26_fa_pad2 : packoffset(c0.w);\n    float _26_hide : packoffset(c1);\n    float _26_fa_pad3 : packoffset(c1.y);\n    float _26_fa_pad4 : packoffset(c1.z);\n    float _26_fa_pad5 : packoffset(c1.w);\n    float _26_spacing : packoffset(c2);\n    float _26_fa_pad6 : packoffset(c2.y);\n    float _26_fa_pad7 : packoffset(c2.z);\n    float _26_fa_pad8 : packoffset(c2.w);\n};\n\nRWByteAddressBuffer points : register(u0);\n\nstatic uint3 gl_WorkGroupID;\nstatic uint3 gl_LocalInvocationID;\nstatic uint3 gl_GlobalInvocationID;\nstatic uint gl_LocalInvocationIndex;\nstruct SPIRV_Cross_Input\n{\n    uint3 gl_WorkGroupID : SV_GroupID;\n    uint3 gl_LocalInvocationID : SV_GroupThreadID;\n    uint3 gl_GlobalInvocationID : SV_DispatchThreadID;\n    uint gl_LocalInvocationIndex : SV_GroupIndex;\n};\n\nvoid compute(ComputeInput i)\n{\n    float _23 = float(i.global_id.x);\n    if (_23 >= _26_count)\n    {\n        return;\n    }\n    points.Store4(i.global_id.x * 32 + 0, asuint(float4((_23 - 2.0f) * _26_spacing, 0.0f, 0.0f, (_23 == _26_hide) ? 0.0f : 1.0f)));\n    points.Store4(i.global_id.x * 32 + 16, asuint(float4(1.0f, 0.0f, 0.0f, 1.0f)));\n}\n\nvoid comp_main()\n{\n    ComputeInput _98 = { gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex };\n    ComputeInput param = _98;\n    compute(param);\n}\n\n[numthreads(64, 1, 1)]\nvoid main(SPIRV_Cross_Input stage_input)\n{\n    gl_WorkGroupID = stage_input.gl_WorkGroupID;\n    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;\n    gl_GlobalInvocationID = stage_input.gl_GlobalInvocationID;\n    gl_LocalInvocationIndex = stage_input.gl_LocalInvocationIndex;\n    comp_main();\n}\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main",
          "d3d11_target": "cs_5_0"
        },
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "compute",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_26",
            "hlsl_register_b_n": 0
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 0,
              "stage": "compute",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": false,
              "hlsl_register_u_n": 0
            }
          }
        ]
      }
    }
  }
}
