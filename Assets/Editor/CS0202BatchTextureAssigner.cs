using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public static class CS0202BatchTextureAssigner
{
    private const string MaterialFolder = "Assets/CS0202素材/materials";
    private const string TextureFolder = "Assets/CS0202素材/texture";

    private static readonly Dictionary<string, string> TextureProperties =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            { "D", "_MainTex" },
            { "N", "_NormalMap" },
            { "AO", "_AOMap" },
            { "spec", "_SpecMask" }
        };

    [MenuItem("Tools/CS0202/批量匹配材质贴图")]
    private static void AssignTextures()
    {
        Dictionary<string, Dictionary<string, string>> textureSets = BuildTextureIndex();
        string[] materialGuids = AssetDatabase.FindAssets("t:Material", new[] { MaterialFolder });
        int materialCount = 0;
        int assignedCount = 0;
        var messages = new List<string>();

        foreach (string guid in materialGuids)
        {
            string materialPath = AssetDatabase.GUIDToAssetPath(guid);
            Material material = AssetDatabase.LoadAssetAtPath<Material>(materialPath);
            string key;

            if (material == null || !TryGetNumberKey(material.name, out key))
            {
                messages.Add("跳过（名称不符合编号规则）: " + materialPath);
                continue;
            }

            Dictionary<string, string> textures;
            if (!textureSets.TryGetValue(key, out textures))
            {
                messages.Add("未找到任何匹配贴图: " + material.name);
                continue;
            }

            Undo.RecordObject(material, "CS0202 批量匹配材质贴图");
            int assignedForMaterial = 0;

            foreach (KeyValuePair<string, string> mapping in TextureProperties)
            {
                string texturePath;
                if (!textures.TryGetValue(mapping.Key, out texturePath))
                {
                    messages.Add(string.Format("缺少 {0}: {1}", mapping.Key, material.name));
                    continue;
                }

                if (!material.HasProperty(mapping.Value))
                {
                    messages.Add(string.Format("Shader 缺少属性 {0}: {1}", mapping.Value, material.name));
                    continue;
                }

                if (mapping.Key.Equals("N", StringComparison.OrdinalIgnoreCase))
                {
                    SetAsNormalMap(texturePath);
                }

                Texture texture = AssetDatabase.LoadAssetAtPath<Texture>(texturePath);
                material.SetTexture(mapping.Value, texture);
                assignedForMaterial++;
                assignedCount++;
            }

            if (assignedForMaterial > 0)
            {
                EditorUtility.SetDirty(material);
                materialCount++;
            }
        }

        AssetDatabase.SaveAssets();

        string details = messages.Count == 0 ? "无缺失项。" : string.Join("\n", messages);
        Debug.Log(string.Format(
            "CS0202 批量上贴图完成：更新 {0} 个材质，共绑定 {1} 张贴图。\n{2}",
            materialCount, assignedCount, details));
        EditorUtility.DisplayDialog(
            "CS0202 批量上贴图",
            string.Format("完成：更新 {0} 个材质，共绑定 {1} 张贴图。\n详细信息请查看 Console。", materialCount, assignedCount),
            "确定");
    }

    private static Dictionary<string, Dictionary<string, string>> BuildTextureIndex()
    {
        var result = new Dictionary<string, Dictionary<string, string>>(StringComparer.OrdinalIgnoreCase);
        string[] guids = AssetDatabase.FindAssets("t:Texture", new[] { TextureFolder });

        foreach (string guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            string fileName = Path.GetFileNameWithoutExtension(path);
            string[] parts = fileName.Split('_');
            string key;

            if (parts.Length < 2 || !TryGetNumberKey(parts[0], out key))
            {
                continue;
            }

            string type = parts[parts.Length - 1];
            if (!TextureProperties.ContainsKey(type))
            {
                continue;
            }

            Dictionary<string, string> set;
            if (!result.TryGetValue(key, out set))
            {
                set = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                result.Add(key, set);
            }

            set[type] = path;
        }

        return result;
    }

    private static bool TryGetNumberKey(string name, out string key)
    {
        key = null;
        string[] parts = name.Split('-');
        int first;
        int last;

        if (parts.Length != 3 || !int.TryParse(parts[0], out first) || !int.TryParse(parts[2], out last))
        {
            return false;
        }

        key = first + "-" + last;
        return true;
    }

    private static void SetAsNormalMap(string texturePath)
    {
        TextureImporter importer = AssetImporter.GetAtPath(texturePath) as TextureImporter;
        if (importer == null || importer.textureType == TextureImporterType.NormalMap)
        {
            return;
        }

        importer.textureType = TextureImporterType.NormalMap;
        importer.SaveAndReimport();
    }
}
