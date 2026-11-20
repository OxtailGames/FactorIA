{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "988cfc1c160a2406bf9dc799340ab0aac9eeed94208cd8193e37bfb0d2577a5b",
  "slang": "hlsl5",
  "params": [
    "base"
  ],
  "textures": [],
  "full": true,
  "shadow": "none",
  "prepass": false,
  "passes": [
    {
      "name": "main",
      "cull": "back",
      "depthTest": true,
      "depthWrite": true,
      "blend": "none",
      "program": "mesh",
      "programSkin": "mesh_skin"
    }
  ],
  "programs": {
    "mesh": {
      "vs": "cbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 v_shadow;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nfloat4 fa_shadow_coord(float3 world)\n{\n    return float4(world, 1.0f);\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _109 = fa_world_position(param);\n    v_pos = _109;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    float3 param_2 = _109;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mul(float4(_109, 1.0f), _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    fa_model = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    stage_output.v_shadow = v_shadow;\n    return stage_output;\n}\n",
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _106_fa_camera_pos : packoffset(c0);\n    float4 _106_fa_ambient : packoffset(c1);\n    float4 _106_fa_base_color : packoffset(c2);\n    float4 _106_fa_emissive : packoffset(c3);\n    float4 _106_fa_model_emissive : packoffset(c4);\n    float4 _106_fa_pbr : packoffset(c5);\n    float4 _106_fa_maps : packoffset(c6);\n    float4 _106_fa_fog : packoffset(c7);\n    float4 _106_fa_fog_b : packoffset(c8);\n    float4 _106_fa_fog_c : packoffset(c9);\n    float4 _106_fa_counts : packoffset(c10);\n    float4 _106_fa_env_sky : packoffset(c11);\n    float4 _106_fa_env_horizon : packoffset(c12);\n    float4 _106_fa_time : packoffset(c13);\n    float4 _106_fa_cl_vpx : packoffset(c14);\n    float4 _106_fa_cl_vpy : packoffset(c15);\n    float4 _106_fa_cl_vpw : packoffset(c16);\n    float4 _106_fa_cl_fwd : packoffset(c17);\n    float4 _106_fa_cl_grid : packoffset(c18);\n    float4 _106_fa_cl_info : packoffset(c19);\n    float4 _106_fa_layers_a : packoffset(c20);\n    float4 _106_fa_layers_b : packoffset(c21);\n    float4 _106_fa_layers_c : packoffset(c22);\n    float4 _106_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _637_fa_shadow_mat[4] : packoffset(c0);\n    float4 _637_fa_shadow_rect[4] : packoffset(c16);\n    float4 _637_fa_shadow_info[4] : packoffset(c20);\n    float4 _637_fa_shadow_split : packoffset(c24);\n    float4 _637_fa_shadow_cfg : packoffset(c25);\n    float4 _637_fa_shadow_bias : packoffset(c26);\n    float4 _637_fa_shadow_eye : packoffset(c27);\n    float4 _637_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _1467_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_light_tex : register(t1);\nSamplerState fa_full_shadow_smp : register(s1);\nTexture2D<float4> fa_full_light_atlas : register(t2);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_full_shadow_tex : register(t0);\n\nstatic float4 gl_FragCoord;\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_106_fa_counts.x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_106_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_full_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _151_dummy_parameter;\n    return fa_full_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_full_light_atlas, uint(0), _151_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _191 = dot(d, right);\n    float _195 = dot(d, up);\n    float _206;\n    if (((_191 * _191) + (_195 * _195)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _206 = atan2(_195, _191) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _206 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_206 - floor(_206)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _240 = fa_light_base(param);\n    bool _245 = _106_fa_counts.y > 4.5f;\n    int param_1 = _240;\n    float4 _249 = fa_light_texel(param_1);\n    int param_2 = _240 + 1;\n    float4 _255 = fa_light_texel(param_2);\n    float _259 = _255.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _271 = _245 && (_259 > 2.5f);\n    fa_light_is_area = _271;\n    bool _274 = _259 < 0.5f;\n    float3 l;\n    if (_274)\n    {\n        l = normalize(_249.xyz);\n        if (_245)\n        {\n            int param_3 = _240 + 6;\n            float4 _289 = fa_light_texel(param_3);\n            if (_289.z > 0.5f)\n            {\n                int param_4 = _240 + 4;\n                float4 _300 = fa_light_texel(param_4);\n                int param_5 = _240 + 5;\n                float4 _306 = fa_light_texel(param_5);\n                float2 param_6 = _289.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _300.xyz) * _300.w, (-dot(world_pos, _306.xyz)) * _306.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _338 = _249.xyz - world_pos;\n        float _340 = length(_338);\n        dist = _340;\n        l = _338 / max(_340, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _340;\n        if (_271)\n        {\n            int param_8 = _240 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _372 = reach / max(_249.w, 0.001000000047497451305389404296875f);\n        float _378 = clamp(1.0f - (_372 * _372), 0.0f, 1.0f);\n        atten = _378 * _378;\n        bool _386 = _259 < 2.5f;\n        if ((_259 > 1.5f) && _386)\n        {\n            int param_9 = _240 + 2;\n            float4 _395 = fa_light_texel(param_9);\n            float _405 = _395.w;\n            int param_10 = _240 + 3;\n            float4 _411 = fa_light_texel(param_10);\n            float _412 = _411.x;\n            float cos_inner = _412;\n            if (_412 > 1.5f)\n            {\n                cos_inner = lerp(_405, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_405, cos_inner, dot(-l, normalize(_395.xyz)));\n        }\n        if (_245 && _386)\n        {\n            int param_11 = _240 + 6;\n            float4 _436 = fa_light_texel(param_11);\n            int param_12 = _240 + 7;\n            float4 _441 = fa_light_texel(param_12);\n            bool _444 = _436.z > 0.5f;\n            bool _451;\n            if (!_444)\n            {\n                _451 = _441.z > 0.5f;\n            }\n            else\n            {\n                _451 = _444;\n            }\n            if (_451)\n            {\n                int param_13 = _240 + 2;\n                float4 _458 = fa_light_texel(param_13);\n                float3 _462 = normalize(_458.xyz);\n                int param_14 = _240 + 4;\n                float4 _467 = fa_light_texel(param_14);\n                int param_15 = _240 + 5;\n                float4 _472 = fa_light_texel(param_15);\n                if (_444)\n                {\n                    float3 _480 = -_338;\n                    float _487 = _458.w;\n                    float _503 = 0.5f / max(dot(_480, _462) * (sqrt(max(1.0f - (_487 * _487), 0.0f)) / max(_487, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _436.xy;\n                    float2 param_17 = float2(0.5f + (dot(_480, _467.xyz) * _503), 0.5f - (dot(_480, _472.xyz) * _503));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_441.z > 0.5f)\n                {\n                    float2 param_18 = _441.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _462;\n                    float3 param_21 = _467.xyz;\n                    float3 param_22 = _472.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _1529 = _255.xyz * atten;\n    if (_245)\n    {\n        _1529 *= fa_light_tint;\n    }\n    int _572;\n    if (_274)\n    {\n        _572 = 0;\n    }\n    else\n    {\n        _572 = ((_259 > 1.5f) && (_259 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _1540 = { l, _1529, atten, 1.0f, dist, _572 };\n    return _1540;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _627;\n    if (i == 0)\n    {\n        _627 = _637_fa_shadow_split.x;\n    }\n    else\n    {\n        float _643;\n        if (i == 1)\n        {\n            _643 = _637_fa_shadow_split.y;\n        }\n        else\n        {\n            float _651;\n            if (i == 2)\n            {\n                _651 = _637_fa_shadow_split.z;\n            }\n            else\n            {\n                _651 = _637_fa_shadow_split.w;\n            }\n            _643 = _651;\n        }\n        _627 = _643;\n    }\n    return _627;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _615 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_615), sin(_615)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _690 = max(_637_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _695 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _701 = sqrt(1.0f - (_695 * _695));\n    float _709 = min(_701 / max(_695, 0.20000000298023223876953125f), 4.0f);\n    float _714;\n    if (_637_fa_shadow_bias.y > 0.0f)\n    {\n        _714 = _637_fa_shadow_bias.y;\n    }\n    else\n    {\n        _714 = 1.5f * _637_fa_shadow_info[ci].x;\n    }\n    float4 _739 = mul(float4(world + (n * (_714 * _701)), 1.0f), _637_fa_shadow_mat[ci]);\n    float _746 = _739.x;\n    bool _749 = _746 < _637_fa_shadow_rect[ci].x;\n    bool _758;\n    if (!_749)\n    {\n        _758 = _746 > _637_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _758 = _749;\n    }\n    bool _767;\n    if (!_758)\n    {\n        _767 = _739.y < _637_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _767 = _758;\n    }\n    bool _776;\n    if (!_767)\n    {\n        _776 = _739.y > _637_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _776 = _767;\n    }\n    bool _783;\n    if (!_776)\n    {\n        _783 = _739.z > 1.0f;\n    }\n    else\n    {\n        _783 = _776;\n    }\n    if (_783)\n    {\n        return -1.0f;\n    }\n    float _791;\n    if (_637_fa_shadow_bias.x > 0.0f)\n    {\n        _791 = _637_fa_shadow_bias.x;\n    }\n    else\n    {\n        _791 = 1.5f * _637_fa_shadow_info[ci].x;\n    }\n    float _810 = _739.z - ((_791 * (1.0f + (0.5f * _709))) / _690);\n    float _819 = ((_637_fa_shadow_info[ci].x * min(_709, 3.0f)) * 0.5f) / _690;\n    int _828 = int(_637_fa_shadow_cfg.z + 0.5f);\n    if (_828 == 1)\n    {\n        float2 param = _739.xy;\n        float4 param_1 = _637_fa_shadow_rect[ci];\n        float _839 = fa_shadow_depth(param, param_1);\n        return float(_810 <= _839);\n    }\n    float _846 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _849 = _828 == 2;\n    if (_849)\n    {\n        float _863 = clamp(((_637_fa_shadow_cfg.w * _690) * 0.25f) / _637_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _846;\n            float2 _883 = fa_shadow_vogel(param_2, param_3, param_4) * _863;\n            float2 param_5 = _739.xy + (_883 * _637_fa_shadow_bias.zw);\n            float4 param_6 = _637_fa_shadow_rect[ci];\n            float _894 = fa_shadow_depth(param_5, param_6);\n            if (_894 < (_810 - (length(_883) * _819)))\n            {\n                sum += _894;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_810 - (sum / cnt), 0.0f) * _690) * _637_fa_shadow_cfg.w) / _637_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _938 = _849 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _938; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _938;\n        float param_9 = _846;\n        float2 _957 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _739.xy + (_957 * _637_fa_shadow_bias.zw);\n        float4 param_11 = _637_fa_shadow_rect[ci];\n        float _968 = fa_shadow_depth(param_10, param_11);\n        lit += float((_810 - (length(_957) * _819)) <= _968);\n    }\n    return lit / float(_938);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_106_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _998 = int(_637_fa_shadow_cfg.x + 0.5f);\n    if (_998 < 1)\n    {\n        return 1.0f;\n    }\n    float _1013 = dot(world - _637_fa_shadow_eye.xyz, _637_fa_shadow_fwd.xyz);\n    int param = _998 - 1;\n    if (_1013 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1025 = _998 > 1;\n    bool _1032;\n    if (_1025)\n    {\n        _1032 = _1013 > _637_fa_shadow_split.x;\n    }\n    else\n    {\n        _1032 = _1025;\n    }\n    if (_1032)\n    {\n        ci = 1;\n    }\n    bool _1036 = _998 > 2;\n    bool _1043;\n    if (_1036)\n    {\n        _1043 = _1013 > _637_fa_shadow_split.y;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        ci = 2;\n    }\n    bool _1047 = _998 > 3;\n    bool _1054;\n    if (_1047)\n    {\n        _1054 = _1013 > _637_fa_shadow_split.z;\n    }\n    else\n    {\n        _1054 = _1047;\n    }\n    if (_1054)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _998)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1080 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1080;\n        if (_1080 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_637_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1105;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1105 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1105 = _637_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1124 = _637_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1105, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1135 = clamp((_1013 - (fa_shadow_split_at(param_7) - _1124)) / _1124, 0.0f, 1.0f);\n        if (_1135 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _998)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1156 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1156;\n                if (_1156 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1135);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float3 param = coord.xyz / coord.w.xxx;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1195 = fa_light_sample(param, param_1);\n    float3 _1542 = _1195.color;\n    float _1544 = _1195.shadow;\n    if ((_1195.type == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1195.direction;\n        float _1211 = fa_shadow(param_2, param_3, param_4);\n        _1544 = _1211;\n        _1542 *= _1211;\n    }\n    LightSample _1559 = { _1195.direction, _1542, _1195.attenuation, _1544, _1195._distance, _1195.type };\n    return _1559;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _1224 = _106_fa_fog.w > 0.0f;\n    bool _1231;\n    if (!_1224)\n    {\n        _1231 = _106_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1231 = _1224;\n    }\n    if (_1231)\n    {\n        float3 _1239 = world_pos - _106_fa_camera_pos.xyz;\n        float _1246 = dot(_1239, _106_fa_fog_c.xyz);\n        bool _1250 = _106_fa_fog_c.w > 0.5f;\n        float _1251;\n        if (_1250)\n        {\n            _1251 = _1246;\n        }\n        else\n        {\n            _1251 = length(_1239);\n        }\n        float _1263 = _1251 - _106_fa_fog_b.x;\n        if (_1263 > 0.0f)\n        {\n            float _1272 = _106_fa_fog.w * _1263;\n            float tau = _1272 * _1272;\n            if (_106_fa_fog_b.y > 0.0f)\n            {\n                float _1288;\n                if (_1250)\n                {\n                    _1288 = world_pos.y - (_106_fa_fog_c.y * _1246);\n                }\n                else\n                {\n                    _1288 = _106_fa_camera_pos.y;\n                }\n                float _1309 = lerp(_1288, world_pos.y, clamp(_106_fa_fog_b.x / _1251, 0.0f, 1.0f));\n                float _1313 = world_pos.y - _1309;\n                float _1318 = _1309 - _106_fa_fog_b.z;\n                float _1323 = world_pos.y - _106_fa_fog_b.z;\n                bool _1326 = _1318 <= 0.0f;\n                bool _1327 = !_1326;\n                bool _1333;\n                if (_1327)\n                {\n                    _1333 = _106_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1333 = _1326;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = _106_fa_fog_b.y;\n                }\n                else\n                {\n                    _1334 = _106_fa_fog_b.y * exp(-min(_106_fa_fog_b.w * _1318, 80.0f));\n                }\n                bool _1361;\n                if (_1327)\n                {\n                    _1361 = _106_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1361 = _1326;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = _106_fa_fog_b.y * _1318;\n                }\n                else\n                {\n                    _1362 = (_106_fa_fog_b.y * (1.0f - exp(-min(_106_fa_fog_b.w * _1318, 80.0f)))) / _106_fa_fog_b.w;\n                }\n                bool _1387 = _1323 <= 0.0f;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = _106_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                float _1395;\n                if (_1394)\n                {\n                    _1395 = _106_fa_fog_b.y * _1323;\n                }\n                else\n                {\n                    _1395 = (_106_fa_fog_b.y * (1.0f - exp(-min(_106_fa_fog_b.w * _1323, 80.0f)))) / _106_fa_fog_b.w;\n                }\n                float _1422;\n                if (abs(_1313) < 0.001000000047497451305389404296875f)\n                {\n                    _1422 = _1334;\n                }\n                else\n                {\n                    _1422 = (_1395 - _1362) / _1313;\n                }\n                tau += (_1263 * max(_1422, 0.0f));\n            }\n            result = lerp(result, _106_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _1460 = normalize(v_normal);\n    float3 lit = _106_fa_ambient.xyz * _1467_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1460;\n        float4 param_3 = v_shadow;\n        LightSample _1492 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_1467_base.xyz * _1492.color) * max(dot(_1460, _1492.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1515 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_1515, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_106",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_637",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1467",
            "hlsl_register_b_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_full_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_light_atlas_fa_env_smp",
            "view_name": "fa_full_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "cbuffer fa_skin : register(b3)\n{\n    float4 _71_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _247_fa_view_proj : packoffset(c0);\n    row_major float4x4 _247_fa_light_vp : packoffset(c4);\n    float4 _247_fa_uv_scale : packoffset(c8);\n    float4 _247_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 v_shadow;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_71_fa_joint_rows[_61] * weights[i]);\n        r1 += (_71_fa_joint_rows[_61 + 1] * weights[i]);\n        r2 += (_71_fa_joint_rows[_61 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nfloat4 fa_shadow_coord(float3 world)\n{\n    return float4(world, 1.0f);\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _227 = fa_world_position(param);\n    v_pos = _227;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    float3 param_2 = _227;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mul(float4(_227, 1.0f), _247_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_model = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    stage_output.v_shadow = v_shadow;\n    return stage_output;\n}\n",
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _106_fa_camera_pos : packoffset(c0);\n    float4 _106_fa_ambient : packoffset(c1);\n    float4 _106_fa_base_color : packoffset(c2);\n    float4 _106_fa_emissive : packoffset(c3);\n    float4 _106_fa_model_emissive : packoffset(c4);\n    float4 _106_fa_pbr : packoffset(c5);\n    float4 _106_fa_maps : packoffset(c6);\n    float4 _106_fa_fog : packoffset(c7);\n    float4 _106_fa_fog_b : packoffset(c8);\n    float4 _106_fa_fog_c : packoffset(c9);\n    float4 _106_fa_counts : packoffset(c10);\n    float4 _106_fa_env_sky : packoffset(c11);\n    float4 _106_fa_env_horizon : packoffset(c12);\n    float4 _106_fa_time : packoffset(c13);\n    float4 _106_fa_cl_vpx : packoffset(c14);\n    float4 _106_fa_cl_vpy : packoffset(c15);\n    float4 _106_fa_cl_vpw : packoffset(c16);\n    float4 _106_fa_cl_fwd : packoffset(c17);\n    float4 _106_fa_cl_grid : packoffset(c18);\n    float4 _106_fa_cl_info : packoffset(c19);\n    float4 _106_fa_layers_a : packoffset(c20);\n    float4 _106_fa_layers_b : packoffset(c21);\n    float4 _106_fa_layers_c : packoffset(c22);\n    float4 _106_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _637_fa_shadow_mat[4] : packoffset(c0);\n    float4 _637_fa_shadow_rect[4] : packoffset(c16);\n    float4 _637_fa_shadow_info[4] : packoffset(c20);\n    float4 _637_fa_shadow_split : packoffset(c24);\n    float4 _637_fa_shadow_cfg : packoffset(c25);\n    float4 _637_fa_shadow_bias : packoffset(c26);\n    float4 _637_fa_shadow_eye : packoffset(c27);\n    float4 _637_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _1467_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_light_tex : register(t1);\nSamplerState fa_full_shadow_smp : register(s1);\nTexture2D<float4> fa_full_light_atlas : register(t2);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_full_shadow_tex : register(t0);\n\nstatic float4 gl_FragCoord;\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_106_fa_counts.x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_106_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_full_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _151_dummy_parameter;\n    return fa_full_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_full_light_atlas, uint(0), _151_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _191 = dot(d, right);\n    float _195 = dot(d, up);\n    float _206;\n    if (((_191 * _191) + (_195 * _195)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _206 = atan2(_195, _191) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _206 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_206 - floor(_206)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _240 = fa_light_base(param);\n    bool _245 = _106_fa_counts.y > 4.5f;\n    int param_1 = _240;\n    float4 _249 = fa_light_texel(param_1);\n    int param_2 = _240 + 1;\n    float4 _255 = fa_light_texel(param_2);\n    float _259 = _255.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _271 = _245 && (_259 > 2.5f);\n    fa_light_is_area = _271;\n    bool _274 = _259 < 0.5f;\n    float3 l;\n    if (_274)\n    {\n        l = normalize(_249.xyz);\n        if (_245)\n        {\n            int param_3 = _240 + 6;\n            float4 _289 = fa_light_texel(param_3);\n            if (_289.z > 0.5f)\n            {\n                int param_4 = _240 + 4;\n                float4 _300 = fa_light_texel(param_4);\n                int param_5 = _240 + 5;\n                float4 _306 = fa_light_texel(param_5);\n                float2 param_6 = _289.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _300.xyz) * _300.w, (-dot(world_pos, _306.xyz)) * _306.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _338 = _249.xyz - world_pos;\n        float _340 = length(_338);\n        dist = _340;\n        l = _338 / max(_340, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _340;\n        if (_271)\n        {\n            int param_8 = _240 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _372 = reach / max(_249.w, 0.001000000047497451305389404296875f);\n        float _378 = clamp(1.0f - (_372 * _372), 0.0f, 1.0f);\n        atten = _378 * _378;\n        bool _386 = _259 < 2.5f;\n        if ((_259 > 1.5f) && _386)\n        {\n            int param_9 = _240 + 2;\n            float4 _395 = fa_light_texel(param_9);\n            float _405 = _395.w;\n            int param_10 = _240 + 3;\n            float4 _411 = fa_light_texel(param_10);\n            float _412 = _411.x;\n            float cos_inner = _412;\n            if (_412 > 1.5f)\n            {\n                cos_inner = lerp(_405, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_405, cos_inner, dot(-l, normalize(_395.xyz)));\n        }\n        if (_245 && _386)\n        {\n            int param_11 = _240 + 6;\n            float4 _436 = fa_light_texel(param_11);\n            int param_12 = _240 + 7;\n            float4 _441 = fa_light_texel(param_12);\n            bool _444 = _436.z > 0.5f;\n            bool _451;\n            if (!_444)\n            {\n                _451 = _441.z > 0.5f;\n            }\n            else\n            {\n                _451 = _444;\n            }\n            if (_451)\n            {\n                int param_13 = _240 + 2;\n                float4 _458 = fa_light_texel(param_13);\n                float3 _462 = normalize(_458.xyz);\n                int param_14 = _240 + 4;\n                float4 _467 = fa_light_texel(param_14);\n                int param_15 = _240 + 5;\n                float4 _472 = fa_light_texel(param_15);\n                if (_444)\n                {\n                    float3 _480 = -_338;\n                    float _487 = _458.w;\n                    float _503 = 0.5f / max(dot(_480, _462) * (sqrt(max(1.0f - (_487 * _487), 0.0f)) / max(_487, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _436.xy;\n                    float2 param_17 = float2(0.5f + (dot(_480, _467.xyz) * _503), 0.5f - (dot(_480, _472.xyz) * _503));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_441.z > 0.5f)\n                {\n                    float2 param_18 = _441.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _462;\n                    float3 param_21 = _467.xyz;\n                    float3 param_22 = _472.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _1529 = _255.xyz * atten;\n    if (_245)\n    {\n        _1529 *= fa_light_tint;\n    }\n    int _572;\n    if (_274)\n    {\n        _572 = 0;\n    }\n    else\n    {\n        _572 = ((_259 > 1.5f) && (_259 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _1540 = { l, _1529, atten, 1.0f, dist, _572 };\n    return _1540;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _627;\n    if (i == 0)\n    {\n        _627 = _637_fa_shadow_split.x;\n    }\n    else\n    {\n        float _643;\n        if (i == 1)\n        {\n            _643 = _637_fa_shadow_split.y;\n        }\n        else\n        {\n            float _651;\n            if (i == 2)\n            {\n                _651 = _637_fa_shadow_split.z;\n            }\n            else\n            {\n                _651 = _637_fa_shadow_split.w;\n            }\n            _643 = _651;\n        }\n        _627 = _643;\n    }\n    return _627;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _615 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_615), sin(_615)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _690 = max(_637_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _695 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _701 = sqrt(1.0f - (_695 * _695));\n    float _709 = min(_701 / max(_695, 0.20000000298023223876953125f), 4.0f);\n    float _714;\n    if (_637_fa_shadow_bias.y > 0.0f)\n    {\n        _714 = _637_fa_shadow_bias.y;\n    }\n    else\n    {\n        _714 = 1.5f * _637_fa_shadow_info[ci].x;\n    }\n    float4 _739 = mul(float4(world + (n * (_714 * _701)), 1.0f), _637_fa_shadow_mat[ci]);\n    float _746 = _739.x;\n    bool _749 = _746 < _637_fa_shadow_rect[ci].x;\n    bool _758;\n    if (!_749)\n    {\n        _758 = _746 > _637_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _758 = _749;\n    }\n    bool _767;\n    if (!_758)\n    {\n        _767 = _739.y < _637_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _767 = _758;\n    }\n    bool _776;\n    if (!_767)\n    {\n        _776 = _739.y > _637_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _776 = _767;\n    }\n    bool _783;\n    if (!_776)\n    {\n        _783 = _739.z > 1.0f;\n    }\n    else\n    {\n        _783 = _776;\n    }\n    if (_783)\n    {\n        return -1.0f;\n    }\n    float _791;\n    if (_637_fa_shadow_bias.x > 0.0f)\n    {\n        _791 = _637_fa_shadow_bias.x;\n    }\n    else\n    {\n        _791 = 1.5f * _637_fa_shadow_info[ci].x;\n    }\n    float _810 = _739.z - ((_791 * (1.0f + (0.5f * _709))) / _690);\n    float _819 = ((_637_fa_shadow_info[ci].x * min(_709, 3.0f)) * 0.5f) / _690;\n    int _828 = int(_637_fa_shadow_cfg.z + 0.5f);\n    if (_828 == 1)\n    {\n        float2 param = _739.xy;\n        float4 param_1 = _637_fa_shadow_rect[ci];\n        float _839 = fa_shadow_depth(param, param_1);\n        return float(_810 <= _839);\n    }\n    float _846 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _849 = _828 == 2;\n    if (_849)\n    {\n        float _863 = clamp(((_637_fa_shadow_cfg.w * _690) * 0.25f) / _637_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _846;\n            float2 _883 = fa_shadow_vogel(param_2, param_3, param_4) * _863;\n            float2 param_5 = _739.xy + (_883 * _637_fa_shadow_bias.zw);\n            float4 param_6 = _637_fa_shadow_rect[ci];\n            float _894 = fa_shadow_depth(param_5, param_6);\n            if (_894 < (_810 - (length(_883) * _819)))\n            {\n                sum += _894;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_810 - (sum / cnt), 0.0f) * _690) * _637_fa_shadow_cfg.w) / _637_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _938 = _849 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _938; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _938;\n        float param_9 = _846;\n        float2 _957 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _739.xy + (_957 * _637_fa_shadow_bias.zw);\n        float4 param_11 = _637_fa_shadow_rect[ci];\n        float _968 = fa_shadow_depth(param_10, param_11);\n        lit += float((_810 - (length(_957) * _819)) <= _968);\n    }\n    return lit / float(_938);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_106_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _998 = int(_637_fa_shadow_cfg.x + 0.5f);\n    if (_998 < 1)\n    {\n        return 1.0f;\n    }\n    float _1013 = dot(world - _637_fa_shadow_eye.xyz, _637_fa_shadow_fwd.xyz);\n    int param = _998 - 1;\n    if (_1013 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1025 = _998 > 1;\n    bool _1032;\n    if (_1025)\n    {\n        _1032 = _1013 > _637_fa_shadow_split.x;\n    }\n    else\n    {\n        _1032 = _1025;\n    }\n    if (_1032)\n    {\n        ci = 1;\n    }\n    bool _1036 = _998 > 2;\n    bool _1043;\n    if (_1036)\n    {\n        _1043 = _1013 > _637_fa_shadow_split.y;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        ci = 2;\n    }\n    bool _1047 = _998 > 3;\n    bool _1054;\n    if (_1047)\n    {\n        _1054 = _1013 > _637_fa_shadow_split.z;\n    }\n    else\n    {\n        _1054 = _1047;\n    }\n    if (_1054)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _998)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1080 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1080;\n        if (_1080 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_637_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1105;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1105 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1105 = _637_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1124 = _637_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1105, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1135 = clamp((_1013 - (fa_shadow_split_at(param_7) - _1124)) / _1124, 0.0f, 1.0f);\n        if (_1135 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _998)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1156 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1156;\n                if (_1156 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1135);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float3 param = coord.xyz / coord.w.xxx;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1195 = fa_light_sample(param, param_1);\n    float3 _1542 = _1195.color;\n    float _1544 = _1195.shadow;\n    if ((_1195.type == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1195.direction;\n        float _1211 = fa_shadow(param_2, param_3, param_4);\n        _1544 = _1211;\n        _1542 *= _1211;\n    }\n    LightSample _1559 = { _1195.direction, _1542, _1195.attenuation, _1544, _1195._distance, _1195.type };\n    return _1559;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _1224 = _106_fa_fog.w > 0.0f;\n    bool _1231;\n    if (!_1224)\n    {\n        _1231 = _106_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1231 = _1224;\n    }\n    if (_1231)\n    {\n        float3 _1239 = world_pos - _106_fa_camera_pos.xyz;\n        float _1246 = dot(_1239, _106_fa_fog_c.xyz);\n        bool _1250 = _106_fa_fog_c.w > 0.5f;\n        float _1251;\n        if (_1250)\n        {\n            _1251 = _1246;\n        }\n        else\n        {\n            _1251 = length(_1239);\n        }\n        float _1263 = _1251 - _106_fa_fog_b.x;\n        if (_1263 > 0.0f)\n        {\n            float _1272 = _106_fa_fog.w * _1263;\n            float tau = _1272 * _1272;\n            if (_106_fa_fog_b.y > 0.0f)\n            {\n                float _1288;\n                if (_1250)\n                {\n                    _1288 = world_pos.y - (_106_fa_fog_c.y * _1246);\n                }\n                else\n                {\n                    _1288 = _106_fa_camera_pos.y;\n                }\n                float _1309 = lerp(_1288, world_pos.y, clamp(_106_fa_fog_b.x / _1251, 0.0f, 1.0f));\n                float _1313 = world_pos.y - _1309;\n                float _1318 = _1309 - _106_fa_fog_b.z;\n                float _1323 = world_pos.y - _106_fa_fog_b.z;\n                bool _1326 = _1318 <= 0.0f;\n                bool _1327 = !_1326;\n                bool _1333;\n                if (_1327)\n                {\n                    _1333 = _106_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1333 = _1326;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = _106_fa_fog_b.y;\n                }\n                else\n                {\n                    _1334 = _106_fa_fog_b.y * exp(-min(_106_fa_fog_b.w * _1318, 80.0f));\n                }\n                bool _1361;\n                if (_1327)\n                {\n                    _1361 = _106_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1361 = _1326;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = _106_fa_fog_b.y * _1318;\n                }\n                else\n                {\n                    _1362 = (_106_fa_fog_b.y * (1.0f - exp(-min(_106_fa_fog_b.w * _1318, 80.0f)))) / _106_fa_fog_b.w;\n                }\n                bool _1387 = _1323 <= 0.0f;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = _106_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                float _1395;\n                if (_1394)\n                {\n                    _1395 = _106_fa_fog_b.y * _1323;\n                }\n                else\n                {\n                    _1395 = (_106_fa_fog_b.y * (1.0f - exp(-min(_106_fa_fog_b.w * _1323, 80.0f)))) / _106_fa_fog_b.w;\n                }\n                float _1422;\n                if (abs(_1313) < 0.001000000047497451305389404296875f)\n                {\n                    _1422 = _1334;\n                }\n                else\n                {\n                    _1422 = (_1395 - _1362) / _1313;\n                }\n                tau += (_1263 * max(_1422, 0.0f));\n            }\n            result = lerp(result, _106_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _1460 = normalize(v_normal);\n    float3 lit = _106_fa_ambient.xyz * _1467_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1460;\n        float4 param_3 = v_shadow;\n        LightSample _1492 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_1467_base.xyz * _1492.color) * max(dot(_1460, _1492.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1515 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_1515, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          }
        ],
        "uniform_blocks": [
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_247",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_106",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_637",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1467",
            "hlsl_register_b_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_full_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_light_atlas_fa_env_smp",
            "view_name": "fa_full_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
