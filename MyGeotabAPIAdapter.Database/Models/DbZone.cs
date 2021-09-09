﻿using Dapper.Contrib.Extensions;
using System;

namespace MyGeotabAPIAdapter.Database.Models
{
    [Table("Zones")]
    public class DbZone
    {
        [Key]
        public long id { get; set; }
        public string GeotabId { get; set; }
        public DateTime? ActiveFrom { get; set; }
        public DateTime? ActiveTo { get; set; }
        public double? CentroidLatitude { get; set; }
        public double? CentroidLongitude { get; set; }
        public string Comment { get; set; }
        [Write(false)]
        public string CommentOracle { get => Comment; }
        public bool? Displayed { get; set; }
        public string ExternalReference { get; set; }
        public bool? MustIdentifyStops { get; set; }
        public string Name { get; set; }
        public string Points { get; set; }
        public string ZoneTypeIds { get; set; }
        public long? Version { get; set; }
        public int EntityStatus { get; set; }
        public DateTime RecordLastChangedUtc { get; set; }
        [Write(false)]
        public Common.DatabaseWriteOperationType DatabaseWriteOperationType { get; set; }
    }
}
