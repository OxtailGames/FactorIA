{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "hlsl5",
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
      "cs": "struct ComputeInput\n{\n    uint3 global_id;\n    uint3 local_id;\n    uint3 group_id;\n    uint local_index;\n};\n\nstatic const uint3 gl_WorkGroupSize = uint3(8u, 8u, 1u);\n\ncbuffer fa_material : register(b0)\n{\n    float _89_blue : packoffset(c0);\n    float _89_fa_pad0 : packoffset(c0.y);\n    float _89_fa_pad1 : packoffset(c0.z);\n    float _89_fa_pad2 : packoffset(c0.w);\n};\n\nRWTexture2D<unorm float4> field : register(u1);\nTexture2D<float4> src : register(t0);\nSamplerState src_smp : register(s0);\nRWTexture2D<float> count : register(u0);\n\nstatic uint3 gl_WorkGroupID;\nstatic uint3 gl_LocalInvocationID;\nstatic uint3 gl_GlobalInvocationID;\nstatic uint gl_LocalInvocationIndex;\nstruct SPIRV_Cross_Input\n{\n    uint3 gl_WorkGroupID : SV_GroupID;\n    uint3 gl_LocalInvocationID : SV_GroupThreadID;\n    uint3 gl_GlobalInvocationID : SV_DispatchThreadID;\n    uint gl_LocalInvocationIndex : SV_GroupIndex;\n};\n\nuint2 spvImageSize(RWTexture2D<unorm float4> Tex, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(ret.x, ret.y);\n    Param = 0u;\n    return ret;\n}\n\nvoid compute(ComputeInput i)\n{\n    int2 _24 = int2(i.global_id.xy);\n    uint _31_dummy_parameter;\n    int2 _31 = int2(spvImageSize(field, _31_dummy_parameter));\n    int _36 = _24.x;\n    bool _39 = _36 >= _31.x;\n    bool _49;\n    if (!_39)\n    {\n        _49 = _24.y >= _31.y;\n    }\n    else\n    {\n        _49 = _39;\n    }\n    if (_49)\n    {\n        return;\n    }\n    field[_24] = float4(float(_36 * 16) * 0.0039215688593685626983642578125f, float(_24.y * 16) * 0.0039215688593685626983642578125f, _89_blue * src.SampleLevel(src_smp, 0.5f.xx, 0.0f).w, 1.0f);\n    count[_24] = float4(count[_24].xxxx.x + 1.0f, 0.0f, 0.0f, 0.0f).x;\n}\n\nvoid comp_main()\n{\n    ComputeInput _142 = { gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex };\n    ComputeInput param = _142;\n    compute(param);\n}\n\n[numthreads(8, 8, 1)]\nvoid main(SPIRV_Cross_Input stage_input)\n{\n    gl_WorkGroupID = stage_input.gl_WorkGroupID;\n    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;\n    gl_GlobalInvocationID = stage_input.gl_GlobalInvocationID;\n    gl_LocalInvocationIndex = stage_input.gl_LocalInvocationIndex;\n    comp_main();\n}\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main",
          "d3d11_target": "cs_5_0"
        },
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "compute",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_89",
            "hlsl_register_b_n": 0
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
              "hlsl_register_u_n": 0
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
              "hlsl_register_u_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "compute",
              "name": "src",
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
            "stage": "compute",
            "name": "src_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
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
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
