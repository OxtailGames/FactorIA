{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "c92b9f1a26adc9a735edf9d88d24268eb2cae4ffeaa00748a36617e70a4776c1",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_inst_m0 : TEXCOORD4;\n    float4 fa_inst_m1 : TEXCOORD5;\n    float4 fa_inst_m2 : TEXCOORD6;\n    float4 fa_inst_m3 : TEXCOORD7;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_shadow_pos : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _245 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, position };\n    return _245;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    VertexData _151 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    float3 _251 = _151.world_pos;\n    float4 _158 = float4(_251, 1.0f);\n    fa_world_pos = _251;\n    fa_world_normal = _151.world_normal;\n    fa_world_tangent = _151.world_tangent;\n    fa_uv = _151.uv;\n    fa_shadow_pos = mul(_158, _127_fa_light_vp);\n    gl_Position = mul(_158, _127_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _122_fa_camera_pos : packoffset(c0);\n    float4 _122_fa_ambient : packoffset(c1);\n    float4 _122_fa_base_color : packoffset(c2);\n    float4 _122_fa_emissive : packoffset(c3);\n    float4 _122_fa_model_emissive : packoffset(c4);\n    float4 _122_fa_pbr : packoffset(c5);\n    float4 _122_fa_maps : packoffset(c6);\n    float4 _122_fa_fog : packoffset(c7);\n    float4 _122_fa_counts : packoffset(c8);\n    float4 _122_fa_env_sky : packoffset(c9);\n    float4 _122_fa_env_horizon : packoffset(c10);\n    float4 _122_fa_time : packoffset(c11);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _654_fa_light_pos[32] : packoffset(c0);\n    float4 _654_fa_light_color[32] : packoffset(c32);\n    float4 _654_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_shadow_pos : TEXCOORD4;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _158 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _162 = _158 * _122_fa_base_color;\n    float3 _959 = i.world_normal;\n    if (_122_fa_maps.z > 0.5f)\n    {\n        float3 _192 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _197 = _192.xy * _122_fa_maps.x;\n        float3 _976 = _192;\n        _976.x = _197.x;\n        _976.y = _197.y;\n        SurfaceInput param = i;\n        float3 param_1 = _976;\n        _959 = fa_tangent_normal(param, param_1);\n    }\n    float4 _215 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _971 = { _162.xyz, _162.w, _959, clamp(_122_fa_pbr.x * _215.z, 0.0f, 1.0f), clamp(_122_fa_pbr.y * _215.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_122_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _122_fa_emissive.xyz + (_122_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _971;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_122_fa_time.x * 3.0f)), 0.25f * frac(_122_fa_time.x), 0.0f);\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_122_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _281 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _281;\n    float2 suv = (_281.xy * 0.5f) + 0.5f.xx;\n    if (_122_fa_counts.z > 0.5f)\n    {\n        float3 _981 = p;\n        _981.z = (_981.z * 0.5f) + 0.5f;\n        p = _981;\n    }\n    else\n    {\n        float2 _984 = suv;\n        _984.y = 1.0f - _984.y;\n        suv = _984;\n    }\n    bool _308 = suv.x < 0.0f;\n    bool _315;\n    if (!_308)\n    {\n        _315 = suv.x > 1.0f;\n    }\n    else\n    {\n        _315 = _308;\n    }\n    bool _322;\n    if (!_315)\n    {\n        _322 = suv.y < 0.0f;\n    }\n    else\n    {\n        _322 = _315;\n    }\n    bool _329;\n    if (!_322)\n    {\n        _329 = suv.y > 1.0f;\n    }\n    else\n    {\n        _329 = _322;\n    }\n    bool _336;\n    if (!_329)\n    {\n        _336 = p.z > 1.0f;\n    }\n    else\n    {\n        _336 = _329;\n    }\n    if (_336)\n    {\n        return 1.0f;\n    }\n    float _350 = _122_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _350) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _122_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _491 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _494 = _491.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_494 * _494, exp2((-9.27999973297119140625f) * ndv)) * _494) + _491.y)) + _491.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _411 = rough * rough;\n    float _444 = 0.60000002384185791015625f * _411;\n    return lerp(lerp(_122_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_122_fa_env_horizon.xyz, _122_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _411)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _444, 0.0500000007450580596923828125f + _444, d.y).xxx), ((_122_fa_env_sky.xyz + _122_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_411 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _909 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _909 = -_909;\n    }\n    float3 _551 = _122_fa_camera_pos.xyz - fa_world_pos;\n    float3 _552 = normalize(_551);\n    SurfaceInput _920 = { fa_world_pos, _909, fa_world_tangent, fa_uv, _552, gl_FrontFacing };\n    SurfaceInput param = _920;\n    Surface _557 = fa_standard_surface(param);\n    float3 _928 = _557.albedo;\n    float _929 = _557.alpha;\n    float3 _930 = _557.normal;\n    float _931 = _557.metallic;\n    float _932 = _557.roughness;\n    float _933 = _557.occlusion;\n    float3 _934 = _557.emission;\n    SurfaceInput _927 = { fa_world_pos, _909, fa_world_tangent, fa_uv, _552, gl_FrontFacing };\n    SurfaceInput param_1 = _927;\n    Surface param_2 = _557;\n    surface(param_1, param_2);\n    _928 = param_2.albedo;\n    _929 = param_2.alpha;\n    _930 = param_2.normal;\n    _931 = param_2.metallic;\n    _932 = param_2.roughness;\n    _933 = param_2.occlusion;\n    _934 = param_2.emission;\n    float3 result;\n    if (_122_fa_emissive.w > 0.5f)\n    {\n        result = _928;\n    }\n    else\n    {\n        float3 _579 = normalize(_930);\n        float _586 = clamp(_931, 0.0f, 1.0f);\n        float _590 = clamp(_932, 0.0500000007450580596923828125f, 1.0f);\n        float _594 = _590 * _590;\n        float _598 = _594 * _594;\n        float _604 = max(dot(_579, _552), 9.9999997473787516355514526367188e-05f);\n        float3 _610 = _928 * (1.0f - _586);\n        float3 _618 = lerp(0.039999999105930328369140625f.xxx, _928, _586.xxx);\n        float3 lit = (_122_fa_ambient.xyz * _610) * _933;\n        int _631 = int(_122_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _631)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _660 = _654_fa_light_color[li].w < 0.5f;\n            if (_660)\n            {\n                l = normalize(_654_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _677 = _654_fa_light_pos[li].xyz - fa_world_pos;\n                float _680 = length(_677);\n                l = _677 / max(_680, 9.9999997473787516355514526367188e-05f).xxx;\n                float _695 = _680 / max(_654_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _701 = clamp(1.0f - (_695 * _695), 0.0f, 1.0f);\n                atten = _701 * _701;\n                if (_654_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_654_fa_light_dir[li].w, lerp(_654_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_654_fa_light_dir[li].xyz)));\n                }\n            }\n            float _734 = max(dot(_579, l), 0.0f);\n            if (_660 && (li == 0))\n            {\n                float3 param_3 = _909;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _753 = normalize(l + _552);\n            float _758 = max(dot(_579, _753), 0.0f);\n            float _771 = ((_758 * _758) * (_598 - 1.0f)) + 1.0f;\n            lit += (((_610 + (((_618 + ((1.0f.xxx - _618) * pow(1.0f - max(dot(_552, _753), 0.0f), 5.0f))) * (((_598 / ((3.1415927410125732421875f * _771) * _771)) * (0.5f / max(lerp((2.0f * _734) * _604, _734 + _604, _594), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _734))) * _654_fa_light_color[li].xyz) * (_734 * atten));\n        }\n        float param_5 = _590;\n        float param_6 = _604;\n        float2 _839 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_552, _579);\n        float param_8 = _590;\n        float3 _857 = lit;\n        float3 _858 = _857 + ((fa_environment(param_7, param_8) * ((_618 * _839.x) + _839.y.xxx)) * _933);\n        lit = _858;\n        result = _858;\n    }\n    result += _934;\n    if (_122_fa_fog.w > 0.0f)\n    {\n        float _882 = _122_fa_fog.w * length(_551);\n        result = lerp(result, _122_fa_fog.xyz, clamp(1.0f - exp((-_882) * _882), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _929);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_122",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_654",
            "hlsl_register_b_n": 2
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _132_fa_view_proj : packoffset(c0);\n    row_major float4x4 _132_fa_light_vp : packoffset(c4);\n    float4 _132_fa_uv_scale : packoffset(c8);\n    float4 _132_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _176_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_inst_m0 : TEXCOORD4;\n    float4 fa_inst_m1 : TEXCOORD5;\n    float4 fa_inst_m2 : TEXCOORD6;\n    float4 fa_inst_m3 : TEXCOORD7;\n    float4 fa_joints : TEXCOORD8;\n    float4 fa_weights : TEXCOORD9;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_shadow_pos : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _167 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_176_fa_joint_rows[_167] * weights[i]);\n        r1 += (_176_fa_joint_rows[_167 + 1] * weights[i]);\n        r2 += (_176_fa_joint_rows[_167 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float3 _70 = cross(model[1].xyz, model[2].xyz);\n    float _76 = (dot(model[0].xyz, _70) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _366 = { mul(float4(position, 1.0f), model).xyz, (((_70 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _76, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _76), texcoord0 * _132_fa_uv_scale.xy, position };\n    return _366;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    VertexData _264 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    float3 _372 = _264.world_pos;\n    float4 _271 = float4(_372, 1.0f);\n    fa_world_pos = _372;\n    fa_world_normal = _264.world_normal;\n    fa_world_tangent = _264.world_tangent;\n    fa_uv = _264.uv;\n    fa_shadow_pos = mul(_271, _132_fa_light_vp);\n    gl_Position = mul(_271, _132_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _122_fa_camera_pos : packoffset(c0);\n    float4 _122_fa_ambient : packoffset(c1);\n    float4 _122_fa_base_color : packoffset(c2);\n    float4 _122_fa_emissive : packoffset(c3);\n    float4 _122_fa_model_emissive : packoffset(c4);\n    float4 _122_fa_pbr : packoffset(c5);\n    float4 _122_fa_maps : packoffset(c6);\n    float4 _122_fa_fog : packoffset(c7);\n    float4 _122_fa_counts : packoffset(c8);\n    float4 _122_fa_env_sky : packoffset(c9);\n    float4 _122_fa_env_horizon : packoffset(c10);\n    float4 _122_fa_time : packoffset(c11);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _654_fa_light_pos[32] : packoffset(c0);\n    float4 _654_fa_light_color[32] : packoffset(c32);\n    float4 _654_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_shadow_pos : TEXCOORD4;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _158 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _162 = _158 * _122_fa_base_color;\n    float3 _959 = i.world_normal;\n    if (_122_fa_maps.z > 0.5f)\n    {\n        float3 _192 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _197 = _192.xy * _122_fa_maps.x;\n        float3 _976 = _192;\n        _976.x = _197.x;\n        _976.y = _197.y;\n        SurfaceInput param = i;\n        float3 param_1 = _976;\n        _959 = fa_tangent_normal(param, param_1);\n    }\n    float4 _215 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _971 = { _162.xyz, _162.w, _959, clamp(_122_fa_pbr.x * _215.z, 0.0f, 1.0f), clamp(_122_fa_pbr.y * _215.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_122_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _122_fa_emissive.xyz + (_122_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _971;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_122_fa_time.x * 3.0f)), 0.25f * frac(_122_fa_time.x), 0.0f);\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_122_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _281 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _281;\n    float2 suv = (_281.xy * 0.5f) + 0.5f.xx;\n    if (_122_fa_counts.z > 0.5f)\n    {\n        float3 _981 = p;\n        _981.z = (_981.z * 0.5f) + 0.5f;\n        p = _981;\n    }\n    else\n    {\n        float2 _984 = suv;\n        _984.y = 1.0f - _984.y;\n        suv = _984;\n    }\n    bool _308 = suv.x < 0.0f;\n    bool _315;\n    if (!_308)\n    {\n        _315 = suv.x > 1.0f;\n    }\n    else\n    {\n        _315 = _308;\n    }\n    bool _322;\n    if (!_315)\n    {\n        _322 = suv.y < 0.0f;\n    }\n    else\n    {\n        _322 = _315;\n    }\n    bool _329;\n    if (!_322)\n    {\n        _329 = suv.y > 1.0f;\n    }\n    else\n    {\n        _329 = _322;\n    }\n    bool _336;\n    if (!_329)\n    {\n        _336 = p.z > 1.0f;\n    }\n    else\n    {\n        _336 = _329;\n    }\n    if (_336)\n    {\n        return 1.0f;\n    }\n    float _350 = _122_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _350) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _122_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _491 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _494 = _491.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_494 * _494, exp2((-9.27999973297119140625f) * ndv)) * _494) + _491.y)) + _491.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _411 = rough * rough;\n    float _444 = 0.60000002384185791015625f * _411;\n    return lerp(lerp(_122_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_122_fa_env_horizon.xyz, _122_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _411)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _444, 0.0500000007450580596923828125f + _444, d.y).xxx), ((_122_fa_env_sky.xyz + _122_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_411 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _909 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _909 = -_909;\n    }\n    float3 _551 = _122_fa_camera_pos.xyz - fa_world_pos;\n    float3 _552 = normalize(_551);\n    SurfaceInput _920 = { fa_world_pos, _909, fa_world_tangent, fa_uv, _552, gl_FrontFacing };\n    SurfaceInput param = _920;\n    Surface _557 = fa_standard_surface(param);\n    float3 _928 = _557.albedo;\n    float _929 = _557.alpha;\n    float3 _930 = _557.normal;\n    float _931 = _557.metallic;\n    float _932 = _557.roughness;\n    float _933 = _557.occlusion;\n    float3 _934 = _557.emission;\n    SurfaceInput _927 = { fa_world_pos, _909, fa_world_tangent, fa_uv, _552, gl_FrontFacing };\n    SurfaceInput param_1 = _927;\n    Surface param_2 = _557;\n    surface(param_1, param_2);\n    _928 = param_2.albedo;\n    _929 = param_2.alpha;\n    _930 = param_2.normal;\n    _931 = param_2.metallic;\n    _932 = param_2.roughness;\n    _933 = param_2.occlusion;\n    _934 = param_2.emission;\n    float3 result;\n    if (_122_fa_emissive.w > 0.5f)\n    {\n        result = _928;\n    }\n    else\n    {\n        float3 _579 = normalize(_930);\n        float _586 = clamp(_931, 0.0f, 1.0f);\n        float _590 = clamp(_932, 0.0500000007450580596923828125f, 1.0f);\n        float _594 = _590 * _590;\n        float _598 = _594 * _594;\n        float _604 = max(dot(_579, _552), 9.9999997473787516355514526367188e-05f);\n        float3 _610 = _928 * (1.0f - _586);\n        float3 _618 = lerp(0.039999999105930328369140625f.xxx, _928, _586.xxx);\n        float3 lit = (_122_fa_ambient.xyz * _610) * _933;\n        int _631 = int(_122_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _631)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _660 = _654_fa_light_color[li].w < 0.5f;\n            if (_660)\n            {\n                l = normalize(_654_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _677 = _654_fa_light_pos[li].xyz - fa_world_pos;\n                float _680 = length(_677);\n                l = _677 / max(_680, 9.9999997473787516355514526367188e-05f).xxx;\n                float _695 = _680 / max(_654_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _701 = clamp(1.0f - (_695 * _695), 0.0f, 1.0f);\n                atten = _701 * _701;\n                if (_654_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_654_fa_light_dir[li].w, lerp(_654_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_654_fa_light_dir[li].xyz)));\n                }\n            }\n            float _734 = max(dot(_579, l), 0.0f);\n            if (_660 && (li == 0))\n            {\n                float3 param_3 = _909;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _753 = normalize(l + _552);\n            float _758 = max(dot(_579, _753), 0.0f);\n            float _771 = ((_758 * _758) * (_598 - 1.0f)) + 1.0f;\n            lit += (((_610 + (((_618 + ((1.0f.xxx - _618) * pow(1.0f - max(dot(_552, _753), 0.0f), 5.0f))) * (((_598 / ((3.1415927410125732421875f * _771) * _771)) * (0.5f / max(lerp((2.0f * _734) * _604, _734 + _604, _594), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _734))) * _654_fa_light_color[li].xyz) * (_734 * atten));\n        }\n        float param_5 = _590;\n        float param_6 = _604;\n        float2 _839 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_552, _579);\n        float param_8 = _590;\n        float3 _857 = lit;\n        float3 _858 = _857 + ((fa_environment(param_7, param_8) * ((_618 * _839.x) + _839.y.xxx)) * _933);\n        lit = _858;\n        result = _858;\n    }\n    result += _934;\n    if (_122_fa_fog.w > 0.0f)\n    {\n        float _882 = _122_fa_fog.w * length(_551);\n        result = lerp(result, _122_fa_fog.xyz, clamp(1.0f - exp((-_882) * _882), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _929);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_132",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_176",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_122",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_654",
            "hlsl_register_b_n": 2
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
